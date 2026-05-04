package models

import "gorm.io/gorm"

// CartItem menyimpan item di keranjang belanja per user
type CartItem struct {
	gorm.Model
	UserID    uint    `gorm:"not null;index"           json:"user_id"`
	ProductID uint    `gorm:"not null;index"           json:"product_id"`
	Quantity  int     `gorm:"not null;default:1"       json:"quantity"`
	Product   Product `gorm:"foreignKey:ProductID"     json:"product,omitempty"`
}

// DTO
type AddToCartRequest struct {
	ProductID uint `json:"product_id" binding:"required"`
	Quantity  int  `json:"quantity"   binding:"required,min=1"`
}

type UpdateCartRequest struct {
	Quantity int `json:"quantity" binding:"required,min=1"`
}

type CartResponse struct {
	Items      []CartItem `json:"items"`
	TotalItems int        `json:"total_items"`
	TotalPrice float64    `json:"total_price"`
}
