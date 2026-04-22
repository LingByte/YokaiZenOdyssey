package models

import (
	"time"

	"gorm.io/gorm"
)

// SaveGame 存档模型
type SaveGame struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	UserID    uint           `gorm:"not null;index" json:"user_id"`
	Slot      int            `gorm:"not null;index" json:"slot"` // 存档槽位 (1-8)
	Character string         `gorm:"size:50;not null" json:"character"` // 角色名称 (悟空, 八戒)
	Data      string         `gorm:"type:text" json:"data"` // 存档数据 (JSON)
	Level     string         `gorm:"size:100" json:"level"` // 当前关卡
	PlayTime  int            `gorm:"default:0" json:"play_time"` // 游戏时长（秒）
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

// TableName 指定表名
func (SaveGame) TableName() string {
	return "save_games"
}

// CreateSaveGame 创建存档
func CreateSaveGame(db *gorm.DB, save *SaveGame) error {
	return db.Create(save).Error
}

// GetSaveGameByUserAndSlot 根据用户ID和槽位获取存档
func GetSaveGameByUserAndSlot(db *gorm.DB, userID uint, slot int) (*SaveGame, error) {
	var save SaveGame
	err := db.Where("user_id = ? AND slot = ?", userID, slot).First(&save).Error
	if err != nil {
		return nil, err
	}
	return &save, nil
}

// GetSaveGamesByUserID 获取用户所有存档
func GetSaveGamesByUserID(db *gorm.DB, userID uint) ([]SaveGame, error) {
	var saves []SaveGame
	err := db.Where("user_id = ?", userID).Order("slot ASC").Find(&saves).Error
	if err != nil {
		return nil, err
	}
	return saves, nil
}

// UpdateSaveGame 更新存档
func UpdateSaveGame(db *gorm.DB, save *SaveGame) error {
	return db.Save(save).Error
}

// DeleteSaveGame 删除存档
func DeleteSaveGame(db *gorm.DB, id uint) error {
	return db.Delete(&SaveGame{}, id).Error
}

// DeleteSaveGameBySlot 删除指定槽位的存档
func DeleteSaveGameBySlot(db *gorm.DB, userID uint, slot int) error {
	return db.Where("user_id = ? AND slot = ?", userID, slot).Delete(&SaveGame{}).Error
}

// CountSaveGamesByUser 统计用户存档数量
func CountSaveGamesByUser(db *gorm.DB, userID uint) (int64, error) {
	var count int64
	err := db.Model(&SaveGame{}).Where("user_id = ?", userID).Count(&count).Error
	return count, err
}
