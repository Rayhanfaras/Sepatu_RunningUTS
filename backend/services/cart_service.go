package services

import (
	"errors"

	"github.com/Rayhanfaras/Sepatu_RunningUTS/models"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/repositories"
)

type CartService struct {
	cartRepo    *repositories.CartRepository
	productRepo *repositories.ProductRepository
}

func NewCartService() *CartService {
	return &CartService{
		cartRepo:    repositories.NewCartRepository(),
		productRepo: repositories.NewProductRepository(),
	}
}

func (s *CartService) GetCart(userID uint) (*models.CartResponse, error) {
	items, err := s.cartRepo.GetByUserID(userID)
	if err != nil {
		return nil, err
	}

	var totalPrice float64
	for _, item := range items {
		totalPrice += item.Product.Price * float64(item.Quantity)
	}

	return &models.CartResponse{
		Items:      items,
		TotalItems: len(items),
		TotalPrice: totalPrice,
	}, nil
}

func (s *CartService) AddToCart(userID uint, req *models.AddToCartRequest) (*models.CartItem, error) {
	// Cek produk ada dan aktif
	product, err := s.productRepo.FindByID(req.ProductID)
	if err != nil {
		return nil, errors.New("produk tidak ditemukan")
	}
	if !product.IsActive {
		return nil, errors.New("produk tidak tersedia")
	}
	if product.Stock < req.Quantity {
		return nil, errors.New("stok tidak mencukupi")
	}

	// Jika sudah ada di cart, tambah quantity
	existing, err := s.cartRepo.GetItem(userID, req.ProductID)
	if err == nil {
		newQty := existing.Quantity + req.Quantity
		if product.Stock < newQty {
			return nil, errors.New("stok tidak mencukupi")
		}
		if err := s.cartRepo.UpdateQuantity(existing.ID, newQty); err != nil {
			return nil, err
		}
		existing.Quantity = newQty
		existing.Product = *product
		return existing, nil
	}

	// Buat item baru
	item := &models.CartItem{
		UserID:    userID,
		ProductID: req.ProductID,
		Quantity:  req.Quantity,
	}
	if err := s.cartRepo.AddItem(item); err != nil {
		return nil, err
	}
	item.Product = *product
	return item, nil
}

func (s *CartService) UpdateItem(itemID, userID uint, req *models.UpdateCartRequest) (*models.CartItem, error) {
	// Verifikasi item milik user
	items, err := s.cartRepo.GetByUserID(userID)
	if err != nil {
		return nil, err
	}

	var target *models.CartItem
	for i := range items {
		if items[i].ID == itemID {
			target = &items[i]
			break
		}
	}
	if target == nil {
		return nil, errors.New("item tidak ditemukan")
	}

	// Cek stok
	if target.Product.Stock < req.Quantity {
		return nil, errors.New("stok tidak mencukupi")
	}

	if err := s.cartRepo.UpdateQuantity(itemID, req.Quantity); err != nil {
		return nil, err
	}
	target.Quantity = req.Quantity
	return target, nil
}

func (s *CartService) RemoveItem(itemID, userID uint) error {
	return s.cartRepo.DeleteItem(itemID, userID)
}

func (s *CartService) ClearCart(userID uint) error {
	return s.cartRepo.ClearCart(userID)
}
