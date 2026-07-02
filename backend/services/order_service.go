package services

import (
	"errors"
	"fmt"
	"math/rand"
	"time"

	"github.com/Rayhanfaras/Sepatu_RunningUTS/models"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/repositories"
)

type OrderService struct {
	orderRepo *repositories.OrderRepository
	cartRepo  *repositories.CartRepository
}

func NewOrderService() *OrderService {
	return &OrderService{
		orderRepo: repositories.NewOrderRepository(),
		cartRepo:  repositories.NewCartRepository(),
	}
}

func (s *OrderService) Checkout(userID uint, req *models.CheckoutRequest) (*models.Order, error) {
	// 1. Dapatkan item di keranjang
	items, err := s.cartRepo.GetByUserID(userID)
	if err != nil {
		return nil, err
	}
	if len(items) == 0 {
		return nil, errors.New("keranjang kosong")
	}

	// 2. Hitung total harga
	var totalPrice float64
	for _, item := range items {
		totalPrice += float64(item.Quantity) * item.Product.Price
	}

	// 3. Generate unique reference
	rand.Seed(time.Now().UnixNano())
	reference := fmt.Sprintf("ORD-%d%04d", time.Now().Unix(), rand.Intn(10000))

	// 4. Buat order baru
	order := &models.Order{
		UserID:          userID,
		TotalPrice:      totalPrice,
		Status:          "pending",
		PaymentMethod:   req.PaymentMethod,
		ShippingAddress: req.ShippingAddress,
		Notes:           req.Notes,
		Reference:       reference,
	}

	if err := s.orderRepo.Create(order); err != nil {
		return nil, err
	}

	// 5. Bersihkan keranjang
	if err := s.cartRepo.ClearCart(userID); err != nil {
		return nil, err
	}

	return order, nil
}

func (s *OrderService) GetOrderStatus(ref string) (*models.Order, error) {
	return s.orderRepo.FindByReference(ref)
}

func (s *OrderService) ConfirmPayment(userID uint, req *models.ConfirmPaymentRequest) (*models.Order, error) {
	order, err := s.orderRepo.FindByReference(req.Reference)
	if err != nil {
		return nil, err
	}

	if order.UserID != userID {
		return nil, errors.New("akses ditolak")
	}

	status := "failed"
	if req.Status == "success" {
		status = "success"
	}

	if err := s.orderRepo.UpdateStatus(req.Reference, status); err != nil {
		return nil, err
	}

	order.Status = status
	return order, nil
}
