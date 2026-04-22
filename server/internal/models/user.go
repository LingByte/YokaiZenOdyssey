package models

import (
	"time"

	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Username  string         `gorm:"uniqueIndex;size:50;not null" json:"username"`
	Password  string         `gorm:"size:255;not null" json:"-"` // 不返回密码
	Email     string         `gorm:"uniqueIndex;size:100" json:"email"`
	Nickname  string         `gorm:"size:50" json:"nickname"`
	Avatar    string         `gorm:"size:255" json:"avatar"`
	Status    int            `gorm:"default:1;comment:1=active,0=inactive" json:"status"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

// TableName 指定表名
func (User) TableName() string {
	return "users"
}

// CreateUser 创建用户
func CreateUser(db *gorm.DB, user *User) error {
	return db.Create(user).Error
}

// GetUserByID 根据ID获取用户
func GetUserByID(db *gorm.DB, id uint) (*User, error) {
	var user User
	err := db.First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// GetUserByUsername 根据用户名获取用户
func GetUserByUsername(db *gorm.DB, username string) (*User, error) {
	var user User
	err := db.Where("username = ?", username).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// GetUserByEmail 根据邮箱获取用户
func GetUserByEmail(db *gorm.DB, email string) (*User, error) {
	var user User
	err := db.Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// UpdateUser 更新用户
func UpdateUser(db *gorm.DB, user *User) error {
	return db.Save(user).Error
}

// DeleteUser 删除用户（软删除）
func DeleteUser(db *gorm.DB, id uint) error {
	return db.Delete(&User{}, id).Error
}

// ListUsers 获取用户列表
func ListUsers(db *gorm.DB, offset, limit int) ([]User, int64, error) {
	var users []User
	var total int64

	// 获取总数
	if err := db.Model(&User{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 获取分页数据
	if err := db.Offset(offset).Limit(limit).Find(&users).Error; err != nil {
		return nil, 0, err
	}

	return users, total, nil
}
