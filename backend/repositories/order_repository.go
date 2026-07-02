package repositories

import (
	"github.com/Rayhanfaras/Sepatu_RunningUTS/config"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/models"
)

type OrderRepository struct{}

func NewOrderRepository() *OrderRepository {
	return &OrderRepository{}
}

func (r *OrderRepository) Create(order *models.Order) error {
	return config.DB.Create(order).Error
}

func (r *OrderRepository) FindByReference(ref string) (*models.Order, error) {
	var order models.Order
	err := config.DB.Where("reference = ?", ref).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *OrderRepository) UpdateStatus(ref string, status string) error {
	return config.DB.Model(&models.Order{}).Where("reference = ?", ref).Update("status", status).Error
}
