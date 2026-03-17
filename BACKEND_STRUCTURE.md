# 雷电游戏 - 后端结构文档 (BACKEND_STRUCTURE)

## 概述

由于这是一个单机 2D 游戏，"后端"主要指：
- 游戏数据结构
- 场景架构
- 信号系统
- 状态管理

---

## 数据库/数据存储

### 本地存储（未来实现）

| 数据 | 类型 | 存储位置 |
|------|------|----------|
| 最高分 | int | User Data Folder |
| 游戏设置 | Dictionary | config.cfg |

### 存档文件结构（未来）

```json
{
  "high_score": 10000,
  "settings": {
    "volume_master": 1.0,
    "volume_sfx": 1.0,
    "volume_music": 0.7
  },
  "unlocks": {
    "ships": ["default"],
    "difficulty": "normal"
  }
}
```

---

## 游戏数据结构

### 玩家数据

```gdscript
# player.gd
var player_data = {
    "position": Vector2,
    "health": int,        # 当前生命值
    "max_health": int,    # 最大生命值 (3)
    "score": int,         # 当前分数
    "lives": int          # 剩余生命 (3)
}
```

### 敌人数据

```gdscript
# enemy.gd
var enemy_data = {
    "position": Vector2,
    "health": int,        # 当前生命值 (1)
    "speed": float,       # 移动速度 (60)
    "direction": int,     # 移动方向 (1 或 -1)
    "score_value": int    # 击毁获得分数 (100)
}
```

### 子弹数据

```gdscript
# bullet.gd
var bullet_data = {
    "position": Vector2,
    "speed": float,       # 飞行速度 (500-600)
    "damage": int,        # 伤害值 (1)
    "direction": Vector2  # 飞行方向 (向上)
}
```

---

## 场景架构

### 主场景树

```
Main (Node2D)
├── Player (CharacterBody2D)
│   ├── Sprite (Sprite2D)
│   ├── CollisionShape2D
│   └── ShootTimer (Timer)
├── EnemySpawnTimer (Timer)
├── SoundManager (Node)
└── UI (CanvasLayer)
    ├── ScoreLabel (Label)
    └── GameOverLabel (Label)
```

### 动态实例化

```gdscript
# 实例化敌人
var enemy = ENEMY_SCENE.instantiate()
enemy.position = Vector2(random_x, 80)
add_child(enemy)

# 实例化子弹
var bullet = BULLET_SCENE.instantiate()
bullet.position = position + Vector2(0, -35)
get_parent().add_child(bullet)
```

---

## 信号系统

### 自定义信号

```gdscript
# enemy.gd
signal enemy_destroyed(enemy_position: Vector2)

# 发射信号
emit_signal("enemy_destroyed", position)
# 或
enemy_destroyed.emit(position)
```

### 内置信号连接

```gdscript
# main.gd
func _ready():
    # Timer 超时信号
    enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)

    # 敌人被击毁信号
    enemy.enemy_destroyed.connect(_on_enemy_destroyed)
```

### 信号流程图

```
玩家射击 → 子弹发射
   ↓
子弹击中敌人 → bullet._on_area_entered
   ↓
调用 enemy.take_damage(1)
   ↓
敌人生命值 <= 0
   ↓
发射 enemy_destroyed 信号
   ↓
main._on_enemy_destroyed()
   ↓
分数 +100
```

---

## 状态管理

### 游戏状态机

```gdscript
# main.gd
enum GameState {
    MENU,      # 主菜单 (未来)
    PLAYING,   # 游戏中
    PAUSED,    # 暂停 (未来)
    GAME_OVER  # 游戏结束
}

var current_state = GameState.PLAYING
```

### 状态转换

```
[MENU] → (开始游戏) → [PLAYING]
[PLAYING] → (玩家死亡) → [GAME_OVER]
[GAME_OVER] → (按回车) → [PLAYING]
[PLAYING] → (按 ESC) → [PAUSED]
[PAUSED] → (按 ESC) → [PLAYING]
```

---

## API/端点合约

由于是单机游戏，没有传统 API 端点。但有内部"合约"：

### 敌人生成合约

```gdscript
# 输入：无
# 输出：Enemy 实例添加到场景
# 频率：每 1 秒
# 位置：y=80, x=随机 (50-430)
```

### 射击合约

```gdscript
# 输入：玩家位置
# 输出：Bullet 实例添加到场景
# 冷却：0.15 秒
# 位置：玩家前方 35 像素
```

### 碰撞检测合约

```gdscript
# 子弹 → 敌人
条件：Area2D 进入 Area2D
结果：敌人 take_damage(1)，子弹删除

# 敌人 → 玩家
条件：Area2D 进入 Area2D
结果：玩家生命值 -1，敌人删除
```

---

## 认证/授权

**不适用** - 单机游戏，无需用户认证

---

## 边缘情况处理

### 屏幕边界

```gdscript
# 玩家边界
position.x = clamp(position.x, 32, screen_size.x - 32)
position.y = clamp(position.y, 32, screen_size.y - 32)

# 敌人边界
if position.x > 450:
    direction = -1
elif position.x < 30:
    direction = 1
```

### 对象清理

```gdscript
# 子弹超出屏幕
if position.y < -50:
    queue_free()

# 敌人超出屏幕
if position.y > 750:
    queue_free()
```

### 空状态处理

```gdscript
# 检查节点是否存在
var sound_manager = get_node_or_null("SoundManager")
if sound_manager and sound_manager.has_method("play_shoot_sound"):
    sound_manager.play_shoot_sound()
```

---

## 性能优化

### 对象数量限制

| 对象类型 | 最大数量 | 处理方式 |
|----------|----------|----------|
| 敌人 | 无限制 | 超出屏幕自动删除 |
| 子弹 | 无限制 | 超出屏幕自动删除 |
| 星星 | 100 | 循环使用 |

### 内存管理

```gdscript
# 及时删除不需要的对象
func _on_enemy_destroyed(enemy_position):
    score += 100
    # 敌人已经被 queue_free() 删除
```

---

## 配置管理

### 游戏平衡参数

```gdscript
# 玩家
const PLAYER_SPEED = 300.0
const PLAYER_MAX_HEALTH = 3

# 子弹
const BULLET_SPEED = 600.0
const BULLET_DAMAGE = 1
const SHOOT_COOLDOWN = 0.15

# 敌人
const ENEMY_SPEED = 60.0
const ENEMY_HEALTH = 1
const ENEMY_SPAWN_INTERVAL = 1.0
const ENEMY_SCORE_VALUE = 100
```

---

## 错误处理

### 常见错误场景

| 场景 | 错误 | 处理方案 |
|------|------|----------|
| 节点未找到 | get_node() 失败 | 使用 `get_node_or_null()` 检查 |
| 方法不存在 | 调用不存在的方法 | 使用 `has_method()` 检查 |
| 信号连接失败 | 信号不存在 | 确保信号已定义 |
| 资源加载失败 | preload() 失败 | 检查路径是否正确 |

### 调试输出

```gdscript
# 使用 print() 进行调试
print("[Player] 初始化完成，位置：", position)
print("[Bullet] 生成！位置：", position)
print("[Enemy] 被击毁！分数：", score)
```

---

## 数据流图

```
用户输入 (WASD/空格)
    ↓
Player 脚本处理
    ↓
更新位置 / 实例化子弹
    ↓
物理引擎处理碰撞
    ↓
触发 area_entered 信号
    ↓
调用伤害处理函数
    ↓
更新游戏状态 (分数/生命值)
    ↓
更新 UI 显示
```

---

**文档状态**: 进行中
**最后更新**: 2026-03-12
