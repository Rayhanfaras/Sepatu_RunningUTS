package middleware

import (
	"github.com/golang-jwt/jwt/v5"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware memvalidasi Firebase ID Token di setiap request
// Dipasang di route group yang memerlukan autentikasi
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Ambil token dari header Authorization
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success":    false,
				"message":    "Authorization header tidak ditemukan",
				"error_code": "MISSING_TOKEN",
			})
			return
		}

		// 2. Validasi format "Bearer <token>"
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success":    false,
				"message":    "Format token salah. Gunakan: Bearer <token>",
				"error_code": "INVALID_TOKEN_FORMAT",
			})
			return
		}

		tokenString := parts[1]
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			// Pastikan algoritma yang dipakai adalah HS256
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}

			return []byte(os.Getenv("JWT_SECRET")), nil
		})

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success":    false,
				"message":    "Token tidak valid atau kadaluarsa",
				"error_code": "INVALID_TOKEN",
			})
			return
		}

		// 4. Simpan claims ke context Gin agar bisa diakses handler
		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message": "Token claims tidak valid",
			})
			return
		}

		// Set ke context — bisa diakses di handler: c.Get("user_id")
		c.Set("user_id", claims["sub"])
		c.Set("email", claims["email"])
		c.Set("role", claims["role"])
		c.Set("firebase_uid", claims["firebase_uid"])

		//
		//// 3. Verifikasi Firebase ID Token menggunakan Firebase Admin SDK
		//decodedToken, err := config.FirebaseAuth.VerifyIDToken(context.Background(), tokenString)
		//if err != nil {
		//	c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
		//		"success":    false,
		//		"message":    "Token tidak valid atau kadaluarsa",
		//		"error_code": "INVALID_TOKEN",
		//	})
		//	return
		//}
		//
		//// 4. Simpan claims ke context Gin agar bisa diakses handler
		//c.Set("user_id", decodedToken.UID)
		//c.Set("firebase_uid", decodedToken.UID)
		//if email, ok := decodedToken.Claims["email"].(string); ok {
		//	c.Set("email", email)
		//}
		//if role, ok := decodedToken.Claims["role"].(string); ok {
		//	c.Set("role", role)
		//}

		// 5. Lanjutkan ke handler berikutnya
		c.Next()
	}
}

// AdminOnly middleware — hanya role "admin" yang boleh akses
func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, _ := c.Get("role")
		if role != "admin" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"success":    false,
				"message":    "Akses ditolak. Hanya admin yang diizinkan.",
				"error_code": "FORBIDDEN",
			})
			return
		}
		c.Next()
	}
}
