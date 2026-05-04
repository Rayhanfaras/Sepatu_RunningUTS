package logger

import (
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// L adalah logger global yang dipakai di seluruh aplikasi
var L *slog.Logger

// Init menginisialisasi logger dengan output ke stdout + file
// Level dikontrol via env LOG_LEVEL (debug|info|warn|error), default: info
func Init() {
	level := parseLevel(os.Getenv("LOG_LEVEL"))

	// Buat direktori logs jika belum ada
	if err := os.MkdirAll("logs", 0755); err != nil {
		slog.Error("gagal membuat direktori logs", "error", err)
	}

	// Nama file log berdasarkan tanggal hari ini
	logFile := filepath.Join("logs", time.Now().Format("2006-01-02")+".log")
	file, err := os.OpenFile(logFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		slog.Error("gagal membuka file log", "path", logFile, "error", err)
		file = os.Stdout // fallback ke stdout
	}

	// Tulis ke stdout dan file secara bersamaan
	multiWriter := io.MultiWriter(os.Stdout, file)

	opts := &slog.HandlerOptions{
		Level:     level,
		AddSource: level == slog.LevelDebug, // tampilkan file:line hanya di debug
	}

	L = slog.New(slog.NewJSONHandler(multiWriter, opts))
	slog.SetDefault(L) // jadikan default slog juga

	L.Info("logger diinisialisasi",
		"level", level.String(),
		"log_file", logFile,
	)
}

func parseLevel(s string) slog.Level {
	switch strings.ToLower(s) {
	case "debug":
		return slog.LevelDebug
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
