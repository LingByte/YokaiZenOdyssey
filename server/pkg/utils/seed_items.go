package utils

import (
	"fmt"
	"log"

	"github.com/LingByte/YokaiZenOdyssey/internal/models"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// SeedItems 写入物品目录样例（id 与 assets/items/{id}.png 对齐）
func SeedItems(db *gorm.DB) error {
	items := []models.ItemDefinition{
		// 武器
		{ID: 1300, Name: "如意金箍棒", Category: models.CategoryEquipment, EquipSlot: models.SlotWeapon, Rarity: 3, Icon: "1300", Description: "齐天大圣的神兵，攻无不克。", Atk: 25, Crit: 5, AllowedCharacters: "悟空"},
		{ID: 1301, Name: "九齿钉耙", Category: models.CategoryEquipment, EquipSlot: models.SlotWeapon, Rarity: 3, Icon: "1301", Description: "天蓬元帅法宝，力大无穷。", Atk: 22, Def: 3, AllowedCharacters: "八戒"},
		{ID: 1302, Name: "青锋短剑", Category: models.CategoryEquipment, EquipSlot: models.SlotWeapon, Rarity: 1, Icon: "1302", Description: "普通短剑，锋利轻便。", Atk: 8},
		{ID: 1303, Name: "玄铁重棍", Category: models.CategoryEquipment, EquipSlot: models.SlotWeapon, Rarity: 2, Icon: "1303", Description: "沉重的铁棍，适合近战。", Atk: 15, Def: 2},
		// 饰品
		{ID: 1500, Name: "紧箍咒环", Category: models.CategoryEquipment, EquipSlot: models.SlotAccessory, Rarity: 2, Icon: "1500", Description: "略增法力与暴击。", MP: 20, Crit: 3, AllowedCharacters: "悟空"},
		{ID: 1501, Name: "莲花佩", Category: models.CategoryEquipment, EquipSlot: models.SlotAccessory, Rarity: 2, Icon: "1501", Description: "护体生莲，略增防御。", Def: 5, HP: 15, AllowedCharacters: "八戒"},
		{ID: 1502, Name: "辟邪玉佩", Category: models.CategoryEquipment, EquipSlot: models.SlotAccessory, Rarity: 1, Icon: "1502", Description: "普通玉佩，略增幸运。", Luck: 10, MagicRes: 2},
		// 防具（装备槽）
		{ID: 1000000, Name: "虎皮裙", Category: models.CategoryEquipment, EquipSlot: models.SlotArmor, Rarity: 2, Icon: "1000000", Description: "大圣旧装，轻便护身。", Def: 12, HP: 30, Dodge: 3, AllowedCharacters: "悟空"},
		{ID: 1000001, Name: "锦襕袈裟", Category: models.CategoryEquipment, EquipSlot: models.SlotArmor, Rarity: 2, Icon: "1000001", Description: "厚实袈裟，防御不错。", Def: 15, HP: 40, AllowedCharacters: "八戒"},
		{ID: 1000010, Name: "布衣甲", Category: models.CategoryEquipment, EquipSlot: models.SlotArmor, Rarity: 1, Icon: "1000010", Description: "寻常布甲。", Def: 6, HP: 15},
		// 法宝
		{ID: 1000020, Name: "芭蕉扇残片", Category: models.CategoryEquipment, EquipSlot: models.SlotArtifact, Rarity: 3, Icon: "1000020", Description: "神扇碎片，蕴含火焰之力。", Atk: 8, MP: 30, MagicRes: 5},
		{ID: 1000021, Name: "照妖镜", Category: models.CategoryEquipment, EquipSlot: models.SlotArtifact, Rarity: 2, Icon: "1000021", Description: "可辨真伪，略增暴击。", Crit: 8, Luck: 5},
		{ID: 1000022, Name: "定风丹匣", Category: models.CategoryEquipment, EquipSlot: models.SlotArtifact, Rarity: 1, Icon: "1000022", Description: "稳固心神。", Def: 4, ReMP: 2},
		// 道具
		{ID: 1000034, Name: "回春丹", Category: models.CategoryConsumable, Rarity: 1, Stackable: true, MaxStack: 20, Icon: "1000034", Description: "恢复少量生命（效果预留）。", ReHP: 20},
		{ID: 1000044, Name: "聚灵散", Category: models.CategoryConsumable, Rarity: 1, Stackable: true, MaxStack: 20, Icon: "1000044", Description: "恢复少量法力（效果预留）。", ReMP: 20},
		{ID: 1000054, Name: "仙桃", Category: models.CategoryConsumable, Rarity: 2, Stackable: true, MaxStack: 10, Icon: "1000054", Description: "蟠桃园掉落的仙果。", HP: 50, MP: 20},
		// 时装
		{ID: 1311, Name: "行者装", Category: models.CategoryFashion, Rarity: 2, Icon: "1311", Description: "云游四方的装束（仅展示）。"},
		{ID: 1313, Name: "天蓬战甲外观", Category: models.CategoryFashion, Rarity: 2, Icon: "1313", Description: "威风凛凛的外观（仅展示）。"},
		// 经文
		{ID: 1314, Name: "般若心经残卷", Category: models.CategoryScripture, Rarity: 2, Icon: "1314", Description: "诵读可静心（本阶段仅收藏）。"},
		{ID: 1315, Name: "大威德真言", Category: models.CategoryScripture, Rarity: 3, Icon: "1315", Description: "镇妖经文残篇。"},
	}

	for i := range items {
		item := items[i]
		if item.MaxStack <= 0 {
			item.MaxStack = 1
		}
		if item.Icon == "" {
			item.Icon = fmt.Sprintf("%d", item.ID)
		}
		err := db.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "id"}},
			UpdateAll: true,
		}).Create(&item).Error
		if err != nil {
			return fmt.Errorf("seed item %d: %w", item.ID, err)
		}
	}

	log.Printf("Seed items completed (%d definitions)", len(items))
	return nil
}
