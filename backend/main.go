package main

import (
	"log"
	"os"

	"github.com/Rayhanfaras/Sepatu_RunningUTS/config"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/pkg/logger"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/routes"
	"github.com/joho/godotenv"
)

func main() {
	// 1. Load environment variables dari .env file
	if err := godotenv.Load(); err != nil {
		log.Println("File .env tidak ditemukan, menggunakan environment variable sistem")
	}

	// 2. Inisialisasi logger (harus pertama agar semua komponen bisa log)
	logger.Init()

	// 3. Inisialisasi Firebase Admin SDK
	config.InitFirebase()

	// 3. Inisialisasi database + AutoMigrate
	config.InitDatabase()
	// 4. Setup Gin router dengan semua routes
	router := routes.SetupRouter()

	// 5. Jalankan server
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080"
	}

	logger.L.Info("server starting",
		"url", "http://localhost:"+port,
		"health", "http://localhost:"+port+"/v1/health",
	)

	if err := router.Run(":" + port); err != nil {
		logger.L.Error("server gagal berjalan", "error", err)
		log.Fatalf("Gagal menjalankan server: %v", err)
	}
}
