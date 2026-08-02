package handlers

import (
	"net/http"
	"strconv"

	"github.com/LingByte/YokaiZenOdyssey/internal/models"
	"github.com/LingByte/YokaiZenOdyssey/pkg/middleware"
	"github.com/LingByte/YokaiZenOdyssey/pkg/utils"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

const bagCapacity = models.BagSlotCount

type ItemHandler struct {
	db *gorm.DB
}

func NewItemHandler(db *gorm.DB) *ItemHandler {
	return &ItemHandler{db: db}
}

type ItemStatsDTO struct {
	Atk      int `json:"atk"`
	Def      int `json:"def"`
	HP       int `json:"hp"`
	MP       int `json:"mp"`
	Luck     int `json:"luck"`
	Dodge    int `json:"dodge"`
	Crit     int `json:"crit"`
	ReHP     int `json:"re_hp"`
	ReMP     int `json:"re_mp"`
	MagicRes int `json:"magic_res"`
}

type InventorySlotDTO struct {
	InventoryID uint          `json:"inventory_id"`
	BagIndex    int           `json:"bag_index"`
	Quantity    int           `json:"quantity"`
	Item        ItemDefinitionDTO `json:"item"`
}

type ItemDefinitionDTO struct {
	ID                uint   `json:"id"`
	Name              string `json:"name"`
	Category          string `json:"category"`
	EquipSlot         string `json:"equip_slot"`
	Rarity            int    `json:"rarity"`
	Stackable         bool   `json:"stackable"`
	MaxStack          int    `json:"max_stack"`
	Icon              string `json:"icon"`
	Description       string `json:"description"`
	AllowedCharacters string `json:"allowed_characters"`
	ItemStatsDTO
}

type EquippedSlotDTO struct {
	Slot        string             `json:"slot"`
	InventoryID *uint              `json:"inventory_id"`
	Item        *ItemDefinitionDTO `json:"item"`
}

type InventoryResponse struct {
	Slots     []InventorySlotDTO `json:"slots"`
	Equipment []EquippedSlotDTO  `json:"equipment"`
	Stats     ItemStatsDTO       `json:"stats"`
	BagCapacity int              `json:"bag_capacity"`
	Character string             `json:"character"`
}

type GrantRequest struct {
	ItemID   uint `json:"item_id" binding:"required"`
	Quantity int  `json:"quantity"`
}

type EquipRequest struct {
	InventoryID uint `json:"inventory_id" binding:"required"`
}

type UnequipRequest struct {
	Slot string `json:"slot" binding:"required"`
}

type UseRequest struct {
	InventoryID uint `json:"inventory_id" binding:"required"`
}

type MoveRequest struct {
	InventoryID uint `json:"inventory_id" binding:"required"`
	ToIndex     int  `json:"to_index" binding:"min=0"`
}

func defToDTO(d *models.ItemDefinition) ItemDefinitionDTO {
	return ItemDefinitionDTO{
		ID:                d.ID,
		Name:              d.Name,
		Category:          d.Category,
		EquipSlot:         d.EquipSlot,
		Rarity:            d.Rarity,
		Stackable:         d.Stackable,
		MaxStack:          d.MaxStack,
		Icon:              d.Icon,
		Description:       d.Description,
		AllowedCharacters: d.AllowedCharacters,
		ItemStatsDTO: ItemStatsDTO{
			Atk: d.Atk, Def: d.Def, HP: d.HP, MP: d.MP,
			Luck: d.Luck, Dodge: d.Dodge, Crit: d.Crit,
			ReHP: d.ReHP, ReMP: d.ReMP, MagicRes: d.MagicRes,
		},
	}
}

func addStats(a *ItemStatsDTO, d *models.ItemDefinition) {
	a.Atk += d.Atk
	a.Def += d.Def
	a.HP += d.HP
	a.MP += d.MP
	a.Luck += d.Luck
	a.Dodge += d.Dodge
	a.Crit += d.Crit
	a.ReHP += d.ReHP
	a.ReMP += d.ReMP
	a.MagicRes += d.MagicRes
}

func (h *ItemHandler) resolveUserAndSlot(c *gin.Context) (uint, int, *models.SaveGame, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权"})
		return 0, 0, nil, false
	}
	slot, err := strconv.Atoi(c.Param("slot"))
	if err != nil || slot < 1 || slot > 8 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的存档槽位"})
		return 0, 0, nil, false
	}
	save, err := models.GetSaveGameByUserAndSlot(h.db, userID.(uint), slot)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "存档不存在"})
		return 0, 0, nil, false
	}
	return userID.(uint), slot, save, true
}

// ListItems GET /api/items
func (h *ItemHandler) ListItems(c *gin.Context) {
	category := c.Query("category")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "100"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 200 {
		pageSize = 100
	}
	offset := (page - 1) * pageSize
	items, total, err := models.ListItemDefinitions(h.db, category, offset, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询物品失败"})
		return
	}
	dtos := make([]ItemDefinitionDTO, 0, len(items))
	for i := range items {
		dtos = append(dtos, defToDTO(&items[i]))
	}
	c.JSON(http.StatusOK, gin.H{
		"items":     dtos,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// GetItem GET /api/items/:id
func (h *ItemHandler) GetItem(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的物品ID"})
		return
	}
	item, err := models.GetItemDefinitionByID(h.db, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "物品不存在"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"item": defToDTO(item)})
}

func (h *ItemHandler) buildInventoryResponse(userID uint, slot int, save *models.SaveGame) (*InventoryResponse, error) {
	rows, err := models.ListInventoryBySave(h.db, userID, slot)
	if err != nil {
		return nil, err
	}
	loadout, err := models.GetOrCreateLoadout(h.db, userID, slot)
	if err != nil {
		return nil, err
	}

	defCache := map[uint]*models.ItemDefinition{}
	getDef := func(id uint) (*models.ItemDefinition, error) {
		if d, ok := defCache[id]; ok {
			return d, nil
		}
		d, err := models.GetItemDefinitionByID(h.db, id)
		if err != nil {
			return nil, err
		}
		defCache[id] = d
		return d, nil
	}

	slots := make([]InventorySlotDTO, 0)
	for _, row := range rows {
		if row.BagIndex < 0 {
			continue
		}
		def, err := getDef(row.ItemID)
		if err != nil {
			continue
		}
		slots = append(slots, InventorySlotDTO{
			InventoryID: row.ID,
			BagIndex:    row.BagIndex,
			Quantity:    row.Quantity,
			Item:        defToDTO(def),
		})
	}

	stats := ItemStatsDTO{
		HP:   70,
		MP:   100,
		Atk:  10,
		Luck: 70,
	}

	equipDTO := make([]EquippedSlotDTO, 0, 4)
	for _, s := range []string{models.SlotWeapon, models.SlotAccessory, models.SlotArmor, models.SlotArtifact} {
		invPtr := models.LoadoutInvID(loadout, s)
		ed := EquippedSlotDTO{Slot: s, InventoryID: invPtr}
		if invPtr != nil {
			inv, err := models.GetInventoryItemByID(h.db, *invPtr)
			if err == nil {
				if def, err := getDef(inv.ItemID); err == nil {
					dto := defToDTO(def)
					ed.Item = &dto
					addStats(&stats, def)
				}
			}
		}
		equipDTO = append(equipDTO, ed)
	}

	return &InventoryResponse{
		Slots:       slots,
		Equipment:   equipDTO,
		Stats:       stats,
		BagCapacity: bagCapacity,
		Character:   save.Character,
	}, nil
}

// GetInventory GET /api/saves/:slot/inventory
func (h *ItemHandler) GetInventory(c *gin.Context) {
	userID, slot, save, ok := h.resolveUserAndSlot(c)
	if !ok {
		return
	}
	// 确保穿戴槽存在；不再自动塞入默认装备
	_, _ = models.GetOrCreateLoadout(h.db, userID, slot)
	resp, err := h.buildInventoryResponse(userID, slot, save)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取背包失败"})
		return
	}
	c.JSON(http.StatusOK, resp)
}

// GrantItem POST /api/saves/:slot/inventory/grant
func (h *ItemHandler) GrantItem(c *gin.Context) {
	userID, slot, _, ok := h.resolveUserAndSlot(c)
	if !ok {
		return
	}
	var req GrantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Quantity <= 0 {
		req.Quantity = 1
	}
	def, err := models.GetItemDefinitionByID(h.db, req.ItemID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "物品不存在"})
		return
	}

	if def.Stackable {
		existing, err := models.FindStackableInventory(h.db, userID, slot, def.ID)
		if err == nil {
			max := def.MaxStack
			if max <= 0 {
				max = 99
			}
			add := req.Quantity
			if existing.Quantity+add > max {
				add = max - existing.Quantity
			}
			if add <= 0 {
				c.JSON(http.StatusConflict, gin.H{"error": "堆叠已满"})
				return
			}
			existing.Quantity += add
			if err := models.UpdateInventoryItem(h.db, existing); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "发放失败"})
				return
			}
			c.JSON(http.StatusOK, gin.H{"message": "发放成功", "inventory_id": existing.ID, "quantity": existing.Quantity})
			return
		}
	}

	idx, err := models.FindFreeBagIndex(h.db, userID, slot)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}
	qty := req.Quantity
	if !def.Stackable {
		qty = 1
	} else if def.MaxStack > 0 && qty > def.MaxStack {
		qty = def.MaxStack
	}
	row := &models.InventoryItem{
		UserID:    userID,
		SaveSlot:  slot,
		ItemID:    def.ID,
		Quantity:  qty,
		BagIndex: idx,
	}
	if err := models.CreateInventoryItem(h.db, row); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "发放失败"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "发放成功", "inventory_id": row.ID, "bag_index": idx})
}

// EquipItem POST /api/saves/:slot/equipment/equip
func (h *ItemHandler) EquipItem(c *gin.Context) {
	userID, slot, save, ok := h.resolveUserAndSlot(c)
	if !ok {
		return
	}
	var req EquipRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	inv, err := models.GetInventoryItemByID(h.db, req.InventoryID)
	if err != nil || inv.UserID != userID || inv.SaveSlot != slot {
		c.JSON(http.StatusNotFound, gin.H{"error": "背包物品不存在"})
		return
	}
	if inv.BagIndex < 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "物品已装备"})
		return
	}
	def, err := models.GetItemDefinitionByID(h.db, inv.ItemID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "物品定义不存在"})
		return
	}
	if def.Category != models.CategoryEquipment || def.EquipSlot == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "该物品不可装备"})
		return
	}
	if !models.ItemAllowsCharacter(def, save.Character) {
		c.JSON(http.StatusForbidden, gin.H{"error": "当前角色无法穿戴此装备"})
		return
	}

	loadout, err := models.GetOrCreateLoadout(h.db, userID, slot)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "读取装备失败"})
		return
	}

	err = h.db.Transaction(func(tx *gorm.DB) error {
		// 先腾出当前格子，便于替换时旧装备回包
		inv.BagIndex = models.BagIndexEquipped
		if err := models.UpdateInventoryItem(tx, inv); err != nil {
			return err
		}
		if oldID := models.LoadoutInvID(loadout, def.EquipSlot); oldID != nil && *oldID != inv.ID {
			oldInv, err := models.GetInventoryItemByID(tx, *oldID)
			if err == nil {
				free, err := models.FindFreeBagIndex(tx, userID, slot)
				if err != nil {
					return err
				}
				oldInv.BagIndex = free
				if err := models.UpdateInventoryItem(tx, oldInv); err != nil {
					return err
				}
			}
		}
		id := inv.ID
		if !models.SetLoadoutInvID(loadout, def.EquipSlot, &id) {
			return gorm.ErrInvalidData
		}
		return models.UpdateLoadout(tx, loadout)
	})
	if err != nil {
		msg := "装备失败"
		if err.Error() == "背包已满" {
			msg = "背包已满，无法替换当前装备"
		}
		c.JSON(http.StatusConflict, gin.H{"error": msg})
		return
	}

	resp, _ := h.buildInventoryResponse(userID, slot, save)
	c.JSON(http.StatusOK, gin.H{"message": "装备成功", "inventory": resp})
}

// UnequipItem POST /api/saves/:slot/equipment/unequip
func (h *ItemHandler) UnequipItem(c *gin.Context) {
	userID, slot, save, ok := h.resolveUserAndSlot(c)
	if !ok {
		return
	}
	var req UnequipRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	loadout, err := models.GetOrCreateLoadout(h.db, userID, slot)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "读取装备失败"})
		return
	}
	invPtr := models.LoadoutInvID(loadout, req.Slot)
	if invPtr == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "该槽位没有装备"})
		return
	}

	err = h.db.Transaction(func(tx *gorm.DB) error {
		inv, err := models.GetInventoryItemByID(tx, *invPtr)
		if err != nil {
			return err
		}
		free, err := models.FindFreeBagIndex(tx, userID, slot)
		if err != nil {
			return err
		}
		inv.BagIndex = free
		if err := models.UpdateInventoryItem(tx, inv); err != nil {
			return err
		}
		models.SetLoadoutInvID(loadout, req.Slot, nil)
		return models.UpdateLoadout(tx, loadout)
	})
	if err != nil {
		msg := "卸下失败"
		if err.Error() == "背包已满" {
			msg = "背包已满，无法卸下"
		}
		c.JSON(http.StatusConflict, gin.H{"error": msg})
		return
	}

	resp, _ := h.buildInventoryResponse(userID, slot, save)
	c.JSON(http.StatusOK, gin.H{"message": "卸下成功", "inventory": resp})
}

// UseItem POST /api/saves/:slot/inventory/use
func (h *ItemHandler) UseItem(c *gin.Context) {
	userID, slot, save, ok := h.resolveUserAndSlot(c)
	if !ok {
		return
	}
	var req UseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	inv, err := models.GetInventoryItemByID(h.db, req.InventoryID)
	if err != nil || inv.UserID != userID || inv.SaveSlot != slot || inv.BagIndex < 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "背包物品不存在"})
		return
	}
	def, err := models.GetItemDefinitionByID(h.db, inv.ItemID)
	if err != nil || def.Category != models.CategoryConsumable {
		c.JSON(http.StatusBadRequest, gin.H{"error": "该物品不可使用"})
		return
	}
	inv.Quantity--
	if inv.Quantity <= 0 {
		_ = models.DeleteInventoryItem(h.db, inv.ID)
	} else {
		_ = models.UpdateInventoryItem(h.db, inv)
	}
	resp, _ := h.buildInventoryResponse(userID, slot, save)
	c.JSON(http.StatusOK, gin.H{"message": "使用成功", "inventory": resp})
}

// MoveItem POST /api/saves/:slot/inventory/move
func (h *ItemHandler) MoveItem(c *gin.Context) {
	userID, slot, save, ok := h.resolveUserAndSlot(c)
	if !ok {
		return
	}
	var req MoveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.ToIndex < 0 || req.ToIndex >= bagCapacity {
		c.JSON(http.StatusBadRequest, gin.H{"error": "目标格子无效"})
		return
	}
	inv, err := models.GetInventoryItemByID(h.db, req.InventoryID)
	if err != nil || inv.UserID != userID || inv.SaveSlot != slot || inv.BagIndex < 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "背包物品不存在"})
		return
	}
	if inv.BagIndex == req.ToIndex {
		c.JSON(http.StatusOK, gin.H{"message": "无需移动"})
		return
	}

	var other models.InventoryItem
	err = h.db.Where("user_id = ? AND save_slot = ? AND bag_index = ?", userID, slot, req.ToIndex).First(&other).Error
	if err == nil {
		// swap
		otherIdx := inv.BagIndex
		inv.BagIndex = req.ToIndex
		other.BagIndex = otherIdx
		_ = h.db.Transaction(func(tx *gorm.DB) error {
			if err := models.UpdateInventoryItem(tx, inv); err != nil {
				return err
			}
			return models.UpdateInventoryItem(tx, &other)
		})
	} else {
		inv.BagIndex = req.ToIndex
		_ = models.UpdateInventoryItem(h.db, inv)
	}

	resp, _ := h.buildInventoryResponse(userID, slot, save)
	c.JSON(http.StatusOK, gin.H{"message": "移动成功", "inventory": resp})
}

// RegisterRoutes 注册物品与背包路由
func (h *ItemHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api")
	items := api.Group("/items")
	items.Use(middleware.JWTMiddleware())
	{
		items.GET("", h.ListItems)
		items.GET("/:id", h.GetItem)
	}

	saves := api.Group("/saves")
	saves.Use(middleware.JWTMiddleware())
	{
		saves.GET("/:slot/inventory", h.GetInventory)
		saves.POST("/:slot/inventory/grant", h.GrantItem)
		saves.POST("/:slot/inventory/use", h.UseItem)
		saves.POST("/:slot/inventory/move", h.MoveItem)
		saves.POST("/:slot/equipment/equip", h.EquipItem)
		saves.POST("/:slot/equipment/unequip", h.UnequipItem)
	}
}

// GrantStarterKit 创建存档时初始化穿戴栏，并按角色发放开局物品
func GrantStarterKit(db *gorm.DB, userID uint, slot int, character string) error {
	return utils.GrantStarterInventory(db, userID, slot, character)
}
