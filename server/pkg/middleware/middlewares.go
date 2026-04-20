package middleware

import (
	"github.com/LingByte/YokaiZenOdyssey/pkg/constants"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// CorsMiddleware 跨域处理中间件
func CorsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		if origin != "" {
			// 允许具体的 Origin
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
			c.Writer.Header().Set("Vary", "Origin") // 避免缓存污染
		}

		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true") // 允许携带 Cookie
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Origin, X-API-KEY, X-API-SECRET")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}

func InjectDB(db *gorm.DB) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		ctx.Set(constants.DbField, db)
		ctx.Next()
	}
}
