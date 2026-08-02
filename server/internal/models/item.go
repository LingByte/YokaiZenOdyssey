package models

import (
	"errors"
	"time"

	"gorm.io/gorm"
)

const (
	CategoryEquipment  = "equipment"
	CategoryConsumable = "consumable"
	CategoryFashion    = "fashion"
	CategoryScripture  = "scripture"

	SlotWeapon    = "weapon"
	SlotAccessory = "accessory"
	SlotArmor     = "armor"
	SlotArtifact  = "artifact"

	BagSlotCount = 18
	BagIndexEquipped = -1
)

// ItemDefinition 物品目录
type ItemDefinition struct {
	ID                uint      `gorm:"primaryKey" json:"id"`
	Name              string    `gorm:"size:100;not null" json:"name"`
	Category          string    `gorm:"size:32;not null;index" json:"category"`
	EquipSlot         string    `gorm:"size:32" json:"equip_slot"`
	Rarity            int       `gorm:"default:1" json:"rarity"`
	Stackable         bool      `gorm:"default:false" json:"stackable"`
	MaxStack          int       `gorm:"default:1" json:"max_stack"`
	Icon              string    `gorm:"size:255" json:"icon"`
	Description       string    `gorm:"type:text" json:"description"`
	Atk               int       `gorm:"default:0" json:"atk"`
	Def               int       `gorm:"default:0" json:"def"`
	HP                int       `gorm:"default:0" json:"hp"`
	MP                int       `gorm:"default:0" json:"mp"`
	Luck              int       `gorm:"default:0" json:"luck"`
	Dodge             int       `gorm:"default:0" json:"dodge"`
	Crit              int       `gorm:"default:0" json:"crit"`
	ReHP              int       `gorm:"default:0" json:"re_hp"`
	ReMP              int       `gorm:"default:0" json:"re_mp"`
	MagicRes          int       `gorm:"default:0" json:"magic_res"`
	AllowedCharacters string    `gorm:"size:100" json:"allowed_characters"` // 空=全角色，逗号分隔
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

func (ItemDefinition) TableName() string { return "item_definitions" }

// InventoryItem 存档背包条目
type InventoryItem struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	UserID    uint           `gorm:"not null;index:idx_inv_user_slot" json:"user_id"`
	SaveSlot  int            `gorm:"not null;index:idx_inv_user_slot" json:"save_slot"`
	ItemID    uint           `gorm:"not null;index" json:"item_id"`
	Quantity  int            `gorm:"not null;default:1" json:"quantity"`
	BagIndex int            `gorm:"not null;default:0" json:"bag_index"` // 0-17 背包，-1 已装备
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

func (InventoryItem) TableName() string { return "inventory_items" }

// EquipmentLoadout 存档穿戴
type EquipmentLoadout struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	UserID       uint      `gorm:"not null;uniqueIndex:uniq_loadout" json:"user_id"`
	SaveSlot     int       `gorm:"not null;uniqueIndex:uniq_loadout" json:"save_slot"`
	WeaponInvID  *uint     `json:"weapon_inv_id"`
	AccessoryInvID *uint   `json:"accessory_inv_id"`
	ArmorInvID   *uint     `json:"armor_inv_id"`
	ArtifactInvID *uint    `json:"artifact_inv_id"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func (EquipmentLoadout) TableName() string { return "equipment_loadouts" }

// ---- ItemDefinition helpers ----

func GetItemDefinitionByID(db *gorm.DB, id uint) (*ItemDefinition, error) {
	var item ItemDefinition
	if err := db.First(&item, id).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func ListItemDefinitions(db *gorm.DB, category string, offset, limit int) ([]ItemDefinition, int64, error) {
	q := db.Model(&ItemDefinition{})
	if category != "" {
		q = q.Where("category = ?", category)
	}
	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	var items []ItemDefinition
	if err := q.Order("id ASC").Offset(offset).Limit(limit).Find(&items).Error; err != nil {
		return nil, 0, err
	}
	return items, total, nil
}

func CountItemDefinitions(db *gorm.DB) (int64, error) {
	var count int64
	err := db.Model(&ItemDefinition{}).Count(&count).Error
	return count, err
}

func CreateItemDefinition(db *gorm.DB, item *ItemDefinition) error {
	return db.Create(item).Error
}

func ItemAllowsCharacter(def *ItemDefinition, character string) bool {
	if def.AllowedCharacters == "" {
		return true
	}
	for _, part := range splitCSV(def.AllowedCharacters) {
		if part == character {
			return true
		}
	}
	return false
}

func splitCSV(s string) []string {
	var out []string
	start := 0
	for i := 0; i <= len(s); i++ {
		if i == len(s) || s[i] == ',' {
			part := s[start:i]
			// trim spaces
			for len(part) > 0 && part[0] == ' ' {
				part = part[1:]
			}
			for len(part) > 0 && part[len(part)-1] == ' ' {
				part = part[:len(part)-1]
			}
			if part != "" {
				out = append(out, part)
			}
			start = i + 1
		}
	}
	return out
}

// ---- Inventory helpers ----

func GetInventoryItemByID(db *gorm.DB, id uint) (*InventoryItem, error) {
	var row InventoryItem
	if err := db.First(&row, id).Error; err != nil {
		return nil, err
	}
	return &row, nil
}

func ListInventoryBySave(db *gorm.DB, userID uint, slot int) ([]InventoryItem, error) {
	var rows []InventoryItem
	err := db.Where("user_id = ? AND save_slot = ?", userID, slot).Order("bag_index ASC, id ASC").Find(&rows).Error
	return rows, err
}

func CountBagOccupied(db *gorm.DB, userID uint, slot int) (int64, error) {
	var count int64
	err := db.Model(&InventoryItem{}).
		Where("user_id = ? AND save_slot = ? AND bag_index >= 0", userID, slot).
		Count(&count).Error
	return count, err
}

func FindFreeBagIndex(db *gorm.DB, userID uint, slot int) (int, error) {
	var rows []InventoryItem
	if err := db.Where("user_id = ? AND save_slot = ? AND bag_index >= 0", userID, slot).
		Select("bag_index").Find(&rows).Error; err != nil {
		return -1, err
	}
	used := map[int]bool{}
	for _, r := range rows {
		used[r.BagIndex] = true
	}
	for i := 0; i < BagSlotCount; i++ {
		if !used[i] {
			return i, nil
		}
	}
	return -1, errors.New("背包已满")
}

func CreateInventoryItem(db *gorm.DB, row *InventoryItem) error {
	return db.Create(row).Error
}

func UpdateInventoryItem(db *gorm.DB, row *InventoryItem) error {
	return db.Save(row).Error
}

func DeleteInventoryItem(db *gorm.DB, id uint) error {
	return db.Delete(&InventoryItem{}, id).Error
}

func FindStackableInventory(db *gorm.DB, userID uint, slot int, itemID uint) (*InventoryItem, error) {
	var row InventoryItem
	err := db.Where("user_id = ? AND save_slot = ? AND item_id = ? AND bag_index >= 0", userID, slot, itemID).
		First(&row).Error
	if err != nil {
		return nil, err
	}
	return &row, nil
}

// ---- Loadout helpers ----

func GetOrCreateLoadout(db *gorm.DB, userID uint, slot int) (*EquipmentLoadout, error) {
	var loadout EquipmentLoadout
	err := db.Where("user_id = ? AND save_slot = ?", userID, slot).First(&loadout).Error
	if err == nil {
		return &loadout, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	loadout = EquipmentLoadout{UserID: userID, SaveSlot: slot}
	if err := db.Create(&loadout).Error; err != nil {
		return nil, err
	}
	return &loadout, nil
}

func UpdateLoadout(db *gorm.DB, loadout *EquipmentLoadout) error {
	return db.Save(loadout).Error
}

func LoadoutInvID(loadout *EquipmentLoadout, slot string) *uint {
	switch slot {
	case SlotWeapon:
		return loadout.WeaponInvID
	case SlotAccessory:
		return loadout.AccessoryInvID
	case SlotArmor:
		return loadout.ArmorInvID
	case SlotArtifact:
		return loadout.ArtifactInvID
	default:
		return nil
	}
}

func SetLoadoutInvID(loadout *EquipmentLoadout, slot string, id *uint) bool {
	switch slot {
	case SlotWeapon:
		loadout.WeaponInvID = id
	case SlotAccessory:
		loadout.AccessoryInvID = id
	case SlotArmor:
		loadout.ArmorInvID = id
	case SlotArtifact:
		loadout.ArtifactInvID = id
	default:
		return false
	}
	return true
}
