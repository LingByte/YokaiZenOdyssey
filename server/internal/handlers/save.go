package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/LingByte/YokaiZenOdyssey/internal/models"
	"github.com/LingByte/YokaiZenOdyssey/pkg/middleware"
	"gorm.io/gorm"
)

// SaveHandler 存档处理器
type SaveHandler struct {
	db *gorm.DB
}

// NewSaveHandler 创建存档处理器
func NewSaveHandler(db *gorm.DB) *SaveHandler {
	return &SaveHandler{
		db: db,
	}
}

// CreateSaveRequest 创建存档请求
type CreateSaveRequest struct {
	Slot      int    `json:"slot" binding:"required,min=1,max=8"`
	Character string `json:"character" binding:"required,oneof=悟空 八戒"`
	Data      string `json:"data"`
	Level     string `json:"level"`
	PlayTime  int    `json:"play_time"`
}

// UpdateSaveRequest 更新存档请求
type UpdateSaveRequest struct {
	Character string `json:"character" binding:"omitempty,oneof=悟空 八戒"`
	Data      string `json:"data"`
	Level     string `json:"level"`
	PlayTime  int    `json:"play_time"`
}

// SaveResponse 存档响应
type SaveResponse struct {
	ID        uint   `json:"id"`
	UserID    uint   `json:"user_id"`
	Slot      int    `json:"slot"`
	Character string `json:"character"`
	Data      string `json:"data"`
	Level     string `json:"level"`
	PlayTime  int    `json:"play_time"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

// CreateSave 创建存档
func (h *SaveHandler) CreateSave(c *gin.Context) {
	// 从 JWT 中获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	var req CreateSaveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查用户存档数量是否已达到上限
	count, err := models.CountSaveGamesByUser(h.db, userID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询存档失败"})
		return
	}
	if count >= 8 {
		c.JSON(http.StatusConflict, gin.H{"error": "存档槽位已满，最多8个存档"})
		return
	}

	// 检查槽位是否已被占用
	_, err = models.GetSaveGameByUserAndSlot(h.db, userID.(uint), req.Slot)
	if err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "该槽位已被占用"})
		return
	}

	// 创建存档
	save := &models.SaveGame{
		UserID:    userID.(uint),
		Slot:      req.Slot,
		Character: req.Character,
		Data:      req.Data,
		Level:     req.Level,
		PlayTime:  req.PlayTime,
	}

	if err := models.CreateSaveGame(h.db, save); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建存档失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "创建存档成功",
		"save": SaveResponse{
			ID:        save.ID,
			UserID:    save.UserID,
			Slot:      save.Slot,
			Character: save.Character,
			Data:      save.Data,
			Level:     save.Level,
			PlayTime:  save.PlayTime,
			CreatedAt: save.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt: save.UpdatedAt.Format("2006-01-02 15:04:05"),
		},
	})
}

// GetSaves 获取用户所有存档
func (h *SaveHandler) GetSaves(c *gin.Context) {
	// 从 JWT 中获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	saves, err := models.GetSaveGamesByUserID(h.db, userID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取存档失败"})
		return
	}

	// 转换为响应格式
	saveResponses := make([]SaveResponse, 0, len(saves))
	for _, save := range saves {
		saveResponses = append(saveResponses, SaveResponse{
			ID:        save.ID,
			UserID:    save.UserID,
			Slot:      save.Slot,
			Character: save.Character,
			Data:      save.Data,
			Level:     save.Level,
			PlayTime:  save.PlayTime,
			CreatedAt: save.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt: save.UpdatedAt.Format("2006-01-02 15:04:05"),
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"saves": saveResponses,
		"total": len(saveResponses),
	})
}

// GetSaveBySlot 根据槽位获取存档
func (h *SaveHandler) GetSaveBySlot(c *gin.Context) {
	// 从 JWT 中获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	slotStr := c.Param("slot")
	slot, err := strconv.Atoi(slotStr)
	if err != nil || slot < 1 || slot > 8 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的槽位"})
		return
	}

	save, err := models.GetSaveGameByUserAndSlot(h.db, userID.(uint), slot)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "存档不存在"})
		return
	}

	c.JSON(http.StatusOK, SaveResponse{
		ID:        save.ID,
		UserID:    save.UserID,
		Slot:      save.Slot,
		Character: save.Character,
		Data:      save.Data,
		Level:     save.Level,
		PlayTime:  save.PlayTime,
		CreatedAt: save.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt: save.UpdatedAt.Format("2006-01-02 15:04:05"),
	})
}

// UpdateSave 更新存档
func (h *SaveHandler) UpdateSave(c *gin.Context) {
	// 从 JWT 中获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	slotStr := c.Param("slot")
	slot, err := strconv.Atoi(slotStr)
	if err != nil || slot < 1 || slot > 8 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的槽位"})
		return
	}

	var req UpdateSaveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 获取现有存档
	save, err := models.GetSaveGameByUserAndSlot(h.db, userID.(uint), slot)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "存档不存在"})
		return
	}

	// 更新字段
	if req.Character != "" {
		save.Character = req.Character
	}
	if req.Data != "" {
		save.Data = req.Data
	}
	if req.Level != "" {
		save.Level = req.Level
	}
	if req.PlayTime != 0 {
		save.PlayTime = req.PlayTime
	}

	if err := models.UpdateSaveGame(h.db, save); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新存档失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "更新存档成功",
	})
}

// DeleteSave 删除存档
func (h *SaveHandler) DeleteSave(c *gin.Context) {
	// 从 JWT 中获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	slotStr := c.Param("slot")
	slot, err := strconv.Atoi(slotStr)
	if err != nil || slot < 1 || slot > 8 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的槽位"})
		return
	}

	// 删除存档
	if err := models.DeleteSaveGameBySlot(h.db, userID.(uint), slot); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "删除存档失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "删除存档成功",
	})
}

// RegisterRoutes 注册存档相关路由
func (h *SaveHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api")
	saves := api.Group("/saves")
	saves.Use(middleware.JWTMiddleware())
	{
		saves.POST("", h.CreateSave)
		saves.GET("", h.GetSaves)
		saves.GET("/:slot", h.GetSaveBySlot)
		saves.PUT("/:slot", h.UpdateSave)
		saves.DELETE("/:slot", h.DeleteSave)
	}
}
