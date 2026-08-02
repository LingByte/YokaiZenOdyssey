package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/LingByte/YokaiZenOdyssey/internal/models"
	"github.com/LingByte/YokaiZenOdyssey/pkg/jutils"
	"github.com/LingByte/YokaiZenOdyssey/pkg/middleware"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Handler 处理器接口
type Handler interface {
	RegisterRoutes(r *gin.Engine)
}

// UserHandler 用户处理器
type UserHandler struct {
	db *gorm.DB
}

// NewUserHandler 创建用户处理器
func NewUserHandler(db *gorm.DB) *UserHandler {
	return &UserHandler{
		db: db,
	}
}

// LoginRequest 登录请求
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// RegisterRequest 注册请求
type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
	Email    string `json:"email"`
	Nickname string `json:"nickname"`
}

// LoginResponse 登录响应
type LoginResponse struct {
	Token string      `json:"token"`
	User  *UserInfo  `json:"user"`
}

// UserInfo 用户信息（不含密码）
type UserInfo struct {
	ID       uint   `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	Nickname string `json:"nickname"`
	Avatar   string `json:"avatar"`
	Status   int    `json:"status"`
}

// UpdateUserRequest 更新用户请求
type UpdateUserRequest struct {
	Nickname string `json:"nickname"`
	Avatar   string `json:"avatar"`
	Status   int    `json:"status"`
}

// Login 用户登录
func (h *UserHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 根据用户名查找用户
	user, err := models.GetUserByUsername(h.db, req.Username)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "用户名或密码错误"})
		return
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "用户名或密码错误"})
		return
	}

	// 检查用户状态
	if user.Status != 1 {
		c.JSON(http.StatusForbidden, gin.H{"error": "用户已被禁用"})
		return
	}

	// 生成JWT token
	token, err := jutils.GenerateToken(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "生成token失败"})
		return
	}

	// 返回token和用户信息
	c.JSON(http.StatusOK, LoginResponse{
		Token: token,
		User: &UserInfo{
			ID:       user.ID,
			Username: user.Username,
			Email:    user.Email,
			Nickname: user.Nickname,
			Avatar:   user.Avatar,
			Status:   user.Status,
		},
	})
}

// Register 用户注册
func (h *UserHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查用户名是否已存在
	_, err := models.GetUserByUsername(h.db, req.Username)
	if err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "用户名已存在"})
		return
	}

	// 检查邮箱是否已存在
	if req.Email != "" {
		_, err = models.GetUserByEmail(h.db, req.Email)
		if err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "邮箱已被使用"})
			return
		}
	}

	// 加密密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "密码加密失败"})
		return
	}

	// 创建用户
	user := &models.User{
		Username: req.Username,
		Password: string(hashedPassword),
		Email:    req.Email,
		Nickname: req.Nickname,
		Status:   1,
	}

	if err := models.CreateUser(h.db, user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建用户失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "注册成功",
		"user_id": user.ID,
	})
}

// GetUserByID 根据ID获取用户
func (h *UserHandler) GetUserByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户ID"})
		return
	}

	user, err := models.GetUserByID(h.db, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}

	c.JSON(http.StatusOK, UserInfo{
		ID:       user.ID,
		Username: user.Username,
		Email:    user.Email,
		Nickname: user.Nickname,
		Avatar:   user.Avatar,
		Status:   user.Status,
	})
}

// UpdateUser 更新用户信息
func (h *UserHandler) UpdateUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户ID"})
		return
	}

	var req UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := models.GetUserByID(h.db, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}

	// 更新字段
	if req.Nickname != "" {
		user.Nickname = req.Nickname
	}
	if req.Avatar != "" {
		user.Avatar = req.Avatar
	}
	if req.Status != 0 {
		user.Status = req.Status
	}

	if err := models.UpdateUser(h.db, user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新用户失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "更新成功",
	})
}

// DeleteUser 删除用户
func (h *UserHandler) DeleteUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户ID"})
		return
	}

	if err := models.DeleteUser(h.db, uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "删除用户失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "删除成功",
	})
}

// Ping 心跳检测（验证 token 是否有效）
func (h *UserHandler) Ping(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"user_id": userID,
	})
}

// ListUsers 获取用户列表
func (h *UserHandler) ListUsers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	offset := (page - 1) * pageSize

	users, total, err := models.ListUsers(h.db, offset, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取用户列表失败"})
		return
	}

	// 转换为UserInfo列表（不含密码）
	userInfos := make([]UserInfo, 0, len(users))
	for _, user := range users {
		userInfos = append(userInfos, UserInfo{
			ID:       user.ID,
			Username: user.Username,
			Email:    user.Email,
			Nickname: user.Nickname,
			Avatar:   user.Avatar,
			Status:   user.Status,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"users": userInfos,
		"total": total,
		"page":  page,
		"page_size": pageSize,
	})
}

// RegisterRoutes 注册用户相关路由
func (h *UserHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api")
	{
		// 公开路由（不需要认证）
		public := api.Group("/auth")
		{
			public.POST("/login", h.Login)
			public.POST("/register", h.Register)
		}

		// 需要认证的路由
		users := api.Group("/users")
		users.Use(middleware.JWTMiddleware())
		{
			users.POST("/ping", h.Ping)
			users.GET("", h.ListUsers)
			users.GET("/:id", h.GetUserByID)
			users.PUT("/:id", h.UpdateUser)
			users.DELETE("/:id", h.DeleteUser)
		}
	}
}
