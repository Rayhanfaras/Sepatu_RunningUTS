package repositories

import (
	"github.com/Rayhanfaras/Sepatu_RunningUTS/config"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/models"
)

type CartRepository struct{}

func NewCartRepository() *CartRepository {
	return &CartRepository{}
}

func (r *CartRepository) GetByUserID(userID uint) ([]models.CartItem, error) {
	var items []models.CartItem
	err := config.DB.Preload("Product").Where("user_id = ?", userID).Find(&items).Error
	return items, err
}

func (r *CartRepository) GetItem(userID, productID uint) (*models.CartItem, error) {
	var item models.CartItem
	err := config.DB.Where("user_id = ? AND product_id = ?", userID, productID).First(&item).Error
	if err != nil {
		return nil, err
	}
	return &item, nil
}

func (r *CartRepository) AddItem(item *models.CartItem) error {
	return config.DB.Create(item).Error
}

func (r *CartRepository) UpdateQuantity(id uint, quantity int) error {
	return config.DB.Model(&models.CartItem{}).Where("id = ?", id).Update("quantity", quantity).Error
}

func (r *CartRepository) DeleteItem(id, userID uint) error {
	return config.DB.Where("id = ? AND user_id = ?", id, userID).Delete(&models.CartItem{}).Error
}

func (r *CartRepository) ClearCart(userID uint) error {
	return config.DB.Where("user_id = ?", userID).Delete(&models.CartItem{}).Error
}
