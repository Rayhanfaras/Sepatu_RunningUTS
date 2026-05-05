package main

import (
	"log"

	"github.com/Rayhanfaras/Sepatu_RunningUTS/config"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/models"
	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load()
	config.InitDatabase()

	products := []models.Product{
	{
		Name:        "Ortuseight Hyperblast",
		Price:       399000,
		Category:    "Running mils",
		Stock:       50,
		Description: "Sepatu running ringan dengan cushioning empuk, cocok untuk latihan harian",
		ImageURL:    "https://i.ibb.co.com/5xcqt8rJ/mils-running.jpg",
	},
	{
		Name:        "Nike Revolution 6",
		Price:       599000,
		Category:    "Running",
		Stock:       40,
		Description: "Sepatu lari nyaman dengan desain modern dan breathable upper",
		ImageURL:    "https://picsum.photos/401",
	},
	{
		Name:        "Adidas Duramo 10",
		Price:       650000,
		Category:    "Running",
		Stock:       35,
		Description: "Sepatu running dengan bantalan ringan dan responsif untuk jogging",
		ImageURL:    "https://picsum.photos/402",
	},
	{
		Name:        "Puma Velocity Nitro",
		Price:       899000,
		Category:    "Running",
		Stock:       25,
		Description: "Sepatu lari dengan teknologi Nitro foam untuk performa maksimal",
		ImageURL:    "https://picsum.photos/403",
	},
	{
		Name:        "Asics Gel Contend 8",
		Price:       700000,
		Category:    "Running",
		Stock:       30,
		Description: "Sepatu running dengan teknologi Gel untuk kenyamanan dan stabilitas",
		ImageURL:    "https://picsum.photos/404",
	},
}

	for _, p := range products {
		config.DB.Create(&p)
	}
	log.Printf("Seed berhasil: %d produk ditambahkan", len(products))
}
