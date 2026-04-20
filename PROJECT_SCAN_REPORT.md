# 禅妖山海行 - 项目扫描报告

## 📋 项目概览

**项目名称**: 禅妖山海行  
**引擎版本**: Godot 4.5 (GL Compatibility)  
**主场景**: `res://scenes/MainMenu.tscn`  
**窗口尺寸**: 1280x720  
**渲染模式**: GL Compatibility

---

## 🏗️ 项目架构

### 1. 核心系统 (`scripts/systems/`)

#### Global.gd (全局单例)
- **功能**: 全局状态管理和工具函数
- **主要变量**:
  - `token`: 用户认证令牌
  - `is_logged_in`: 登录状态
  - `current_character_id`: 当前角色ID
- **主要方法**:
  - `load_scene(path)`: 场景加载（带加载界面）
  - `set_token(t)`: 设置认证令牌
  - `clear_login()`: 清除登录状态
  - `load_avatar_texture_to(target, url)`: 异步加载头像图片

#### GlobalLoading.gd
- **功能**: 全局加载界面管理器
- **特性**: 带旋转加载动画，支持场景切换

#### ReturnButton.gd
- **功能**: 返回主菜单按钮
- **特性**: 鼠标悬停缩放动画

#### SuccessDialog.gd
- **功能**: 成功提示对话框

---

### 2. 角色系统 (`characters/`)

#### 基础玩家类 (`characters/player/base/BasePlayer.gd`)
- **继承**: `CharacterBody2D`
- **功能**: 基础玩家控制器
- **属性**:
  - `speed`: 200.0
  - `jump_force`: -400.0
  - `gravity`: 1000.0
  - `max_health`: 100
- **功能**:
  - 移动控制（左右移动）
  - 跳跃系统
  - 攻击连击系统（2段攻击）
  - 生命值系统
  - 动画状态管理（idle/run/jump/attack/hurt/die）

#### 玩家类型

**SoulPlayer** (`characters/player/types/SoulPlayer.gd`)
- **继承**: `BasePlayer`
- **自定义**: 
  - `max_health`: 150
  - `speed`: 300.0
  - 使用UI方向键控制

**TangSengPlayer** (`characters/player/types/TangSengPlayer.gd`)
- **继承**: `CharacterBody2D` (独立实现)
- **特性**:
  - 使用Skeleton2D骨骼动画系统
  - 支持武器和身体部位独立控制
  - 更精细的动画控制

#### 敌人系统 (`characters/enemies/`)
- **状态**: 目录存在但内容为空（待实现）

---

### 3. UI系统 (`scripts/ui/`)

#### 主菜单 (`MainMenu.gd`)
- **功能**: 主菜单场景管理
- **特性**:
  - 按钮入场动画（弹性动画）
  - 登录面板管理
  - 存档选择面板管理

#### 登录系统
- **LoginPanel.gd**: 
  - 用户协议和隐私政策弹窗
  - 复选框控制登录按钮状态
  - BBCode富文本支持
- **LoginButton.gd**:
  - HTTP登录请求
  - 登录成功/失败处理
  - 后端API: `http://localhost:7070/api/v1/users/login`

#### 存档系统
- **LoadArchive.gd**:
  - 读取存档列表
  - 存档槽位显示（最多8个）
  - 智能时间显示（刚刚/分钟前/小时前/昨天/日期）
  - 后端API: `http://localhost:7070/api/v1/users/archive`

#### 其他UI组件
- **Backpack.gd**: 背包系统（鼠标交互）
- **AttributeContainer.gd**: 属性容器（动态布局）
- **CloseButton.gd**: 关闭按钮
- **GameExit.gd**: 退出游戏按钮
- **SystemSetButton.gd**: 系统设置按钮
- **newStartButton.gd**: 新游戏按钮（带悬停动画）

---

### 4. 关卡系统 (`scripts/levels/shenxiao/`)

#### 主关卡管理器
- **shenxiao.gd**: 
  - 心跳检测系统（定期ping后端）
  - 背包面板管理
  - 用户头像加载
  - 后端API: `http://localhost:7070/api/v1/users/ping`

#### 关卡脚本
- **LevelExit.gd**: 关卡出口（按W键触发）
- **Lingquan.gd**: 灵泉关卡入口（鼠标交互，发光动画）
- **YuQueQinTianTai.gd**: 玉阙擎天台关卡
- **YuntaiLevel.gd**: 云台关卡
- **YuqueLvel.gd**: 玉阙关卡
- **TianmenLevel.gd**: 天门关卡
- **TianhengLevel.gd**: 天衡关卡
- **TianxingtaiLevel.gd**: 天行台关卡
- **ShenyuhexinLevel.gd**: 神域核心关卡
- **shenxiao_tianmen_instance.gd**: 神霄天门实例
- **pack_close_button.gd**: 背包关闭按钮

---

### 5. 场景文件 (`scenes/`)

#### 主场景
- **MainMenu.tscn**: 主菜单场景

#### 关卡场景
- **Shenxiao.tscn**: 神霄主场景
- **shenxiaoTianmen.tscn**: 神霄天门场景
- **Yuntailingzhen.tscn**: 云台灵阵场景
- **YuQueQinTianTai.tscn**: 玉阙擎天台场景

#### 系统场景
- **GlobalLoading.tscn**: 全局加载场景

---

## 🎮 输入系统

### 输入映射 (`project.godot`)
- **left**: A键
- **right**: D键
- **jump**: K键
- **attack**: J键
- **move_up**: W键

---

## 🌐 后端API集成

### API端点
1. **登录**: `POST http://localhost:7070/api/v1/users/login`
   - 请求体: `{uid, pwd}`
   - 返回: `{code, data: {token}, msg}`

2. **心跳检测**: `POST http://localhost:7070/api/v1/users/ping`
   - 需要Authorization Bearer token

3. **获取存档**: `GET http://localhost:7070/api/v1/users/archive`
   - 需要Authorization Bearer token
   - 返回: `{code, data: {archives: [...]}, msg}`

### 外部资源
- **头像CDN**: `https://cetide-1325039295.cos.ap-chengdu.myqcloud.com/west/`

---

## 📁 资源结构

### 图片资源
- **avatars/**: 头像资源（多种尺寸）
- **avatarframes/**: 头像框
- **button/**: 按钮图片
- **common/**: 通用UI元素（背包、面板等）
- **dialog/**: 对话框背景
- **items/**: 物品图标（394个PNG文件）
- **level/shenxiao/**: 关卡背景图
- **numbers/**: 数字字体图片
- **sprites/**: 角色精灵图
  - **players/**: 玩家角色图（包括tangseng）
  - **enemies/**: 敌人图
  - **character_*.png**: 角色身体部位分解图
- **skeleton/**: 骨骼动画资源（120个PNG文件）

### 字体资源
- **FZSTK.TTF**: 中文字体

---

## 🔍 代码质量分析

### 优点
1. ✅ 良好的代码组织结构（按功能分类）
2. ✅ 使用Godot 4.5新特性（@onready, @export）
3. ✅ 全局单例模式管理状态
4. ✅ 场景加载系统封装良好
5. ✅ UI动画效果丰富

### 潜在问题
1. ⚠️ **硬编码的API地址**: 所有API地址都是`localhost:7070`，应该配置化
2. ⚠️ **错误处理不完善**: HTTP请求失败时只有print，缺少用户提示
3. ⚠️ **敌人系统未实现**: `characters/enemies/`目录为空
4. ⚠️ **部分代码重复**: 多个按钮类有相同的悬停动画代码
5. ⚠️ **魔法数字**: 部分数值硬编码（如存档槽位8个）
6. ⚠️ **缺少注释**: 部分复杂逻辑缺少注释说明

---

## 📊 项目统计

### 文件统计
- **GDScript文件**: ~29个
- **场景文件**: 9个
- **图片资源**: 1000+个
- **关卡脚本**: 12个

### 功能模块
- ✅ 登录系统
- ✅ 存档系统
- ✅ 角色控制系统
- ✅ 关卡系统
- ✅ UI系统
- ⚠️ 敌人系统（待实现）
- ⚠️ 战斗系统（部分实现）
- ⚠️ 物品系统（UI存在，逻辑待完善）

---

## 🚀 建议改进方向

1. **配置管理**: 创建Config.gd统一管理API地址、游戏参数
2. **错误处理**: 添加统一的错误提示系统
3. **代码复用**: 提取按钮悬停动画为基类或工具函数
4. **敌人系统**: 实现敌人基类和类型
5. **存档系统**: 完善本地存档功能
6. **国际化**: 考虑多语言支持
7. **性能优化**: 资源加载优化（异步加载、资源池）
8. **测试**: 添加单元测试和集成测试

---

## 📝 Git状态

### 已修改文件
- `characters/player/base/BasePlayer.gd`
- `project.godot`
- `scenes/MainMenu.tscn`
- `scenes/levels/Yuntailingzhen.tscn`

### 未跟踪文件
- 多个`.uid`文件（Godot自动生成）
- `TangSengPlayer`相关文件
- `YuQueQinTianTai`关卡文件
- 新的资源目录

---

## 🎯 总结

这是一个基于Godot 4.5开发的西游主题2D游戏项目。项目结构清晰，功能模块化良好，已经实现了基础的登录、存档、角色控制和关卡系统。主要需要完善敌人系统、战斗逻辑和错误处理机制。

**项目成熟度**: ⭐⭐⭐☆☆ (3/5)
**代码质量**: ⭐⭐⭐⭐☆ (4/5)
**功能完整性**: ⭐⭐⭐☆☆ (3/5)

---

*报告生成时间: 2025年*
*扫描工具: Cursor AI Assistant*

