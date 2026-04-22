package jutils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var (
	// JWT密钥，生产环境应该从配置文件读取
	JWTSecret = []byte("yokai-zen-odyssey-secret-key-2024")
	// Token过期时间，默认24小时
	TokenExpiration = 24 * time.Hour
)

// Claims JWT声明结构
type Claims struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

// GenerateToken 生成JWT token
func GenerateToken(userID uint, username string) (string, error) {
	claims := Claims{
		UserID:   userID,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(TokenExpiration)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "yokai-zen-odyssey",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(JWTSecret)
}

// ParseToken 解析JWT token
func ParseToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return JWTSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// RefreshToken 刷新token
func RefreshToken(tokenString string) (string, error) {
	claims, err := ParseToken(tokenString)
	if err != nil {
		return "", err
	}

	// 检查token是否即将过期（1小时内）
	if time.Until(claims.ExpiresAt.Time) > time.Hour {
		return tokenString, nil // 不需要刷新
	}

	return GenerateToken(claims.UserID, claims.Username)
}

// ValidateToken 验证token是否有效
func ValidateToken(tokenString string) bool {
	_, err := ParseToken(tokenString)
	return err == nil
}
