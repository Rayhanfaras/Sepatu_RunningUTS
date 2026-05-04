package middleware

import (
	"bytes"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/Rayhanfaras/Sepatu_RunningUTS/pkg/logger"
	"github.com/gin-gonic/gin"
)

// responseBodyWriter membungkus gin.ResponseWriter untuk capture response body
type responseBodyWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (w *responseBodyWriter) Write(b []byte) (int, error) {
	// Simpan hanya 4 KB pertama agar tidak boros memori
	if w.body.Len() < 4096 {
		remaining := 4096 - w.body.Len()
		if len(b) > remaining {
			w.body.Write(b[:remaining])
		} else {
			w.body.Write(b)
		}
	}
	return w.ResponseWriter.Write(b)
}

// HTTPLogger mencatat request masuk dan response keluar untuk setiap endpoint
func HTTPLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		rawQuery := c.Request.URL.RawQuery

		// ── Baca request body ──────────────────────────────────
		var reqBodyStr string
		if c.Request.Body != nil && isLoggableContentType(c.Request.Header.Get("Content-Type")) {
			bodyBytes, err := io.ReadAll(io.LimitReader(c.Request.Body, 4096))
			if err == nil {
				// Kembalikan body agar handler bisa membacanya kembali
				c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
				reqBodyStr = string(bodyBytes)
			}
		}

		// ── Wrap response writer ───────────────────────────────
		rbw := &responseBodyWriter{
			ResponseWriter: c.Writer,
			body:           &bytes.Buffer{},
		}
		c.Writer = rbw

		// ── Log REQUEST ────────────────────────────────────────
		logAttrs := []any{
			slog.String("type", "REQUEST"),
			slog.String("method", c.Request.Method),
			slog.String("path", path),
			slog.String("query", rawQuery),
			slog.String("ip", c.ClientIP()),
			slog.String("user_agent", c.Request.UserAgent()),
		}
		if reqBodyStr != "" {
			logAttrs = append(logAttrs, slog.String("body", reqBodyStr))
		}
		logger.L.Info("incoming request", logAttrs...)

		// ── Jalankan handler ───────────────────────────────────
		c.Next()

		// ── Ambil user_id dari context (setelah auth middleware) ──
		userID, _ := c.Get("user_id")
		role, _ := c.Get("role")

		latency := time.Since(start)
		statusCode := c.Writer.Status()
		respBodyStr := rbw.body.String()

		// ── Pilih log level berdasarkan status code ────────────
		responseAttrs := []any{
			slog.String("type", "RESPONSE"),
			slog.String("method", c.Request.Method),
			slog.String("path", path),
			slog.Int("status", statusCode),
			slog.String("latency", latency.String()),
			slog.Int("resp_size_bytes", c.Writer.Size()),
		}
		if userID != nil {
			responseAttrs = append(responseAttrs, slog.Any("user_id", userID))
		}
		if role != nil {
			responseAttrs = append(responseAttrs, slog.Any("role", role))
		}
		if errMsg := c.Errors.ByType(gin.ErrorTypePrivate).String(); errMsg != "" {
			responseAttrs = append(responseAttrs, slog.String("errors", errMsg))
		}

		switch {
		case statusCode >= http.StatusInternalServerError:
			// 5xx — log body response untuk debug
			responseAttrs = append(responseAttrs, slog.String("resp_body", respBodyStr))
			logger.L.Error("server error response", responseAttrs...)
		case statusCode >= http.StatusBadRequest:
			// 4xx — log body response untuk tahu alasan tolak
			responseAttrs = append(responseAttrs, slog.String("resp_body", respBodyStr))
			logger.L.Warn("client error response", responseAttrs...)
		default:
			logger.L.Info("success response", responseAttrs...)
		}
	}
}

// isLoggableContentType hanya log body untuk JSON dan form
func isLoggableContentType(ct string) bool {
	return strings.Contains(ct, "application/json") ||
		strings.Contains(ct, "application/x-www-form-urlencoded")
}
