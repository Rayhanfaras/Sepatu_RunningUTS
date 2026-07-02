package models

import "gorm.io/gorm"

// Order menyimpan informasi transaksi pembelian
type Order struct {
	gorm.Model
	UserID          uint    `gorm:"not null;index"           json:"user_id"`
	TotalPrice      float64 `gorm:"not null"                 json:"total_price"`
	Status          string  `gorm:"size:20;default:pending"  json:"status"` // pending, success, failed
	PaymentMethod   string  `gorm:"size:50"                  json:"payment_method"`
	ShippingAddress string  `gorm:"size:255"                 json:"shipping_address"`
	Notes           string  `gorm:"size:255"                 json:"notes"`
	Reference       string  `gorm:"size:100;uniqueIndex"     json:"reference"`
}

type CheckoutRequest struct {
	ShippingAddress string `json:"shipping_address" binding:"required"`
	Notes           string `json:"notes"`
	PaymentMethod   string `json:"payment_method" binding:"required"`
}

type ConfirmPaymentRequest struct {
	Reference     string `json:"reference" binding:"required"`
	Status        string `json:"status" binding:"required"` // success, failed
	TransactionID string `json:"transaction_id"`
}
