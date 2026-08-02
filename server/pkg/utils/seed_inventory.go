package utils

import (
	"fmt"
	"log"

	"github.com/LingByte/YokaiZenOdyssey/internal/models"
	"gorm.io/gorm"
)

type starterGrant struct {
	ItemID   uint
	Quantity int
}

// StarterKitForCharacter 按角色返回开局赠礼（物品需已在 SeedItems 中存在）
func StarterKitForCharacter(character string) []starterGrant {
	common := []starterGrant{
		{ItemID: 1000034, Quantity: 5}, // 回春丹
		{ItemID: 1000044, Quantity: 5}, // 聚灵散
		{ItemID: 1000022, Quantity: 1}, // 定风丹匣
		{ItemID: 1314, Quantity: 1},    // 般若心经残卷
	}
	switch character {
	case "八戒":
		return append([]starterGrant{
			{ItemID: 1301, Quantity: 1},    // 九齿钉耙
			{ItemID: 1501, Quantity: 1},    // 莲花佩
			{ItemID: 1000001, Quantity: 1}, // 锦襕袈裟
			{ItemID: 1313, Quantity: 1},    // 天蓬战甲外观
		}, common...)
	default: // 悟空及其他
		return append([]starterGrant{
			{ItemID: 1300, Quantity: 1},    // 如意金箍棒
			{ItemID: 1500, Quantity: 1},    // 紧箍咒环
			{ItemID: 1000000, Quantity: 1}, // 虎皮裙
			{ItemID: 1311, Quantity: 1},    // 行者装
		}, common...)
	}
}

// GrantStarterInventory 向指定存档发放开局物品（已有任意背包条目则跳过，避免重复）
func GrantStarterInventory(db *gorm.DB, userID uint, slot int, character string) error {
	if _, err := models.GetOrCreateLoadout(db, userID, slot); err != nil {
		return err
	}

	var count int64
	if err := db.Model(&models.InventoryItem{}).
		Where("user_id = ? AND save_slot = ?", userID, slot).
		Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	for _, g := range StarterKitForCharacter(character) {
		if err := grantOne(db, userID, slot, g); err != nil {
			return fmt.Errorf("grant item %d: %w", g.ItemID, err)
		}
	}
	return nil
}

func grantOne(db *gorm.DB, userID uint, slot int, g starterGrant) error {
	def, err := models.GetItemDefinitionByID(db, g.ItemID)
	if err != nil {
		return fmt.Errorf("item definition %d missing (run SeedItems first): %w", g.ItemID, err)
	}
	qty := g.Quantity
	if qty <= 0 {
		qty = 1
	}
	if !def.Stackable {
		qty = 1
	} else if def.MaxStack > 0 && qty > def.MaxStack {
		qty = def.MaxStack
	}
	idx, err := models.FindFreeBagIndex(db, userID, slot)
	if err != nil {
		return err
	}
	return models.CreateInventoryItem(db, &models.InventoryItem{
		UserID:    userID,
		SaveSlot:  slot,
		ItemID:    def.ID,
		Quantity:  qty,
		BagIndex: idx,
	})
}

// SeedEmptySaveInventories 为尚无背包物品的存档补发开局礼包
func SeedEmptySaveInventories(db *gorm.DB) error {
	var saves []models.SaveGame
	if err := db.Find(&saves).Error; err != nil {
		return err
	}
	filled := 0
	for _, save := range saves {
		var count int64
		if err := db.Model(&models.InventoryItem{}).
			Where("user_id = ? AND save_slot = ?", save.UserID, save.Slot).
			Count(&count).Error; err != nil {
			return err
		}
		if count > 0 {
			continue
		}
		if err := GrantStarterInventory(db, save.UserID, save.Slot, save.Character); err != nil {
			return fmt.Errorf("seed inventory user=%d slot=%d: %w", save.UserID, save.Slot, err)
		}
		filled++
		log.Printf("Seeded starter inventory for user=%d slot=%d character=%s", save.UserID, save.Slot, save.Character)
	}
	log.Printf("Seed empty save inventories done (filled %d / %d saves)", filled, len(saves))
	return nil
}
