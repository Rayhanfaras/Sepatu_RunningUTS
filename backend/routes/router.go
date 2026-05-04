package routes

import (
	"github.com/Rayhanfaras/Sepatu_RunningUTS/handlers"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/middleware"
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	// Gunakan gin.New() agar kita bisa kontrol penuh urutan middleware
	// (tidak pakai gin.Default() yang auto-include logger bawaan gin)
	r := gin.New()
	r.Use(gin.Recovery()) // panic recovery tetap diperlukan
	r.Use(middleware.HTTPLogger())

	// ─── CORS Middleware ───────────────────────────────────────
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// ─── Init handlers ────────────────────────────────────────
	authHandler := handlers.NewAuthHandler()
	productHandler := handlers.NewProductHandler()
	cartHandler := handlers.NewCartHandler()

	// ─── API v1 group ─────────────────────────────────────────
	v1 := r.Group("/v1")
	{
		// Health check
		v1.GET("/health", func(c *gin.Context) {
			c.JSON(200, gin.H{"status": "ok", "service": "mycatalog-backend"})
		})

		// ── Auth routes (public) ──────────────────────────────
		auth := v1.Group("/auth")
		{
			auth.POST("/verify-token", authHandler.VerifyToken)
		}

		// ── Protected routes (butuh JWT) ──────────────────────
		protected := v1.Group("")
		protected.Use(middleware.AuthMiddleware())
		{
			// Products
			products := protected.Group("/products")
			{
				products.GET("", productHandler.GetAll)

				adminProducts := products.Group("")
				adminProducts.Use(middleware.AdminOnly())
				{
					adminProducts.POST("", productHandler.Create)
				}
			}

			// Cart
			cart := protected.Group("/cart")
			{
				cart.GET("", cartHandler.GetCart)               // GET    /v1/cart
				cart.POST("", cartHandler.AddToCart)            // POST   /v1/cart
				cart.PUT("/:id", cartHandler.UpdateCartItem)    // PUT    /v1/cart/:id
				cart.DELETE("/:id", cartHandler.RemoveCartItem) // DELETE /v1/cart/:id
				cart.DELETE("", cartHandler.ClearCart)          // DELETE /v1/cart
			}

		}
	}

	return r
}
