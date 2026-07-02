package handlers

import (
	"net/http"

	"github.com/Rayhanfaras/Sepatu_RunningUTS/models"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/services"
	"github.com/gin-gonic/gin"
)

type OrderHandler struct {
	orderService *services.OrderService
}

func NewOrderHandler() *OrderHandler {
	return &OrderHandler{orderService: services.NewOrderService()}
}

// Checkout - POST /v1/orders/checkout
func (h *OrderHandler) Checkout(c *gin.Context) {
	userID := getContextUserID(c)

	var req models.CheckoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	order, err := h.orderService.Checkout(userID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Order berhasil dibuat",
		"data":    order,
	})
}

// GetOrderStatus - GET /v1/orders/status/:reference
func (h *OrderHandler) GetOrderStatus(c *gin.Context) {
	reference := c.Param("reference")
	if reference == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Reference tidak boleh kosong"})
		return
	}

	order, err := h.orderService.GetOrderStatus(reference)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Order tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    order,
	})
}

// ConfirmPayment - POST /v1/orders/confirm
func (h *OrderHandler) ConfirmPayment(c *gin.Context) {
	userID := getContextUserID(c)

	var req models.ConfirmPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	order, err := h.orderService.ConfirmPayment(userID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Pembayaran berhasil dikonfirmasi",
		"data":    order,
	})
}
