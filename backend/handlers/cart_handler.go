package handlers

import (
	"net/http"
	"strconv"

	"github.com/Rayhanfaras/Sepatu_RunningUTS/models"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/services"
	"github.com/gin-gonic/gin"
)

type CartHandler struct {
	cartService *services.CartService
}

func NewCartHandler() *CartHandler {
	return &CartHandler{cartService: services.NewCartService()}
}

// GetCart - GET /v1/cart
func (h *CartHandler) GetCart(c *gin.Context) {
	userID := getContextUserID(c)

	cart, err := h.cartService.GetCart(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mengambil keranjang"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": cart})
}

// AddToCart - POST /v1/cart
func (h *CartHandler) AddToCart(c *gin.Context) {
	userID := getContextUserID(c)

	var req models.AddToCartRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	item, err := h.cartService.AddToCart(userID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"success": true, "message": "Produk ditambahkan ke keranjang", "data": item})
}

// UpdateCartItem - PUT /v1/cart/:id
func (h *CartHandler) UpdateCartItem(c *gin.Context) {
	userID := getContextUserID(c)

	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "ID tidak valid"})
		return
	}

	var req models.UpdateCartRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	item, err := h.cartService.UpdateItem(uint(id), userID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Keranjang diperbarui", "data": item})
}

// RemoveCartItem - DELETE /v1/cart/:id
func (h *CartHandler) RemoveCartItem(c *gin.Context) {
	userID := getContextUserID(c)

	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "ID tidak valid"})
		return
	}

	if err := h.cartService.RemoveItem(uint(id), userID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Item tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Item dihapus dari keranjang"})
}

// ClearCart - DELETE /v1/cart
func (h *CartHandler) ClearCart(c *gin.Context) {
	userID := getContextUserID(c)

	if err := h.cartService.ClearCart(userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mengosongkan keranjang"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Keranjang berhasil dikosongkan"})
}

// getContextUserID mengambil user_id dari JWT claims di context
func getContextUserID(c *gin.Context) uint {
	raw, _ := c.Get("user_id")
	switch v := raw.(type) {
	case float64:
		return uint(v)
	case uint:
		return v
	}
	return 0
}
