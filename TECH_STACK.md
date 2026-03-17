# 雷电游戏 - 技术栈文档 (TECH_STACK)

## 核心引擎

| 组件 | 技术/版本 | 用途 |
|------|-----------|------|
| **游戏引擎** | Godot 4.x | 游戏开发和运行 |
| **脚本语言** | GDScript 2.0 | 游戏逻辑编程 |
| **渲染器** | Compatibility | 2D 游戏渲染 |

---

## 项目结构

```
game/
├── project.godot          # Godot 项目配置文件
├── icon.svg               # 游戏图标
├── scenes/                # 游戏场景文件 (.tscn)
│   ├── main.tscn          # 主游戏场景
│   ├── player.tscn        # 玩家飞机场景
│   ├── enemy.tscn         # 敌人场景
│   └── bullet.tscn        # 子弹场景
├── scripts/               # GDScript 脚本文件 (.gd)
│   ├── main.gd            # 主场景逻辑
│   ├── player.gd          # 玩家控制逻辑
│   ├── enemy.gd           # 敌人逻辑
│   ├── bullet.gd          # 子弹逻辑
│   └── sound_manager.gd   # 音效管理
└── assets/                # 资源文件
    └── sprites/           # 精灵图片 (如果需要)
```

---

## 节点类型使用

| 节点类型 | 用途 | 场景 |
|----------|------|------|
| Node2D | 2D 场景根节点 | main.tscn |
| CharacterBody2D | 可移动角色 | player.tscn |
| Area2D | 碰撞检测区域 | enemy.tscn, bullet.tscn |
| Sprite2D | 2D 精灵显示 | 所有场景 |
| CollisionShape2D | 碰撞形状 | 所有场景 |
| Timer | 计时器 | 敌人生成、射击冷却 |
| Label | UI 文本显示 | 分数、游戏结束 |
| CanvasLayer | UI 层 | UI 渲染 |
| AudioStreamPlayer | 音频播放 | 音效管理 |

---

## 碰撞层配置

在 `project.godot` 中定义：

```ini
[layer_names]
2d_physics/layer_1="player"
2d_physics/layer_2="bullets"
2d_physics/layer_3="enemies"
```

| 层 | 名称 | 用于 |
|----|------|------|
| 1 | player | 玩家飞机 |
| 2 | bullets | 子弹 |
| 3 | enemies | 敌人 |

### 碰撞矩阵

| 对象 | Layer | Mask | 检测 |
|------|-------|------|------|
| 玩家 | 1 | 3 | 敌人 |
| 子弹 | 2 | 3 | 敌人 |
| 敌人 | 3 | 2 | 子弹 |

---

## 输入映射

在 `project.godot` 中定义：

```ini
[input]
move_up={...}      # W / ↑
move_down={...}    # S / ↓
move_left={...}    # A / ←
move_right={...}   # D / →
shoot={...}        # 空格键 / 鼠标左键
```

---

## 显示配置

```ini
[display]
window/size/viewport_width=480
window/size/viewport_height=720
window/stretch/mode="viewport"
window/stretch/aspect="expand"
```

| 配置 | 值 | 说明 |
|------|-----|------|
| 分辨率 | 480x720 | 竖版屏幕 |
| 拉伸模式 | viewport | 保持像素完美 |
| 宽高比 | expand | 填充屏幕 |

---

## 代码规范

### 命名约定

| 类型 | 格式 | 示例 |
|------|------|------|
| 变量 | snake_case | `player_speed`, `enemy_count` |
| 函数 | snake_case | `_ready()`, `_process()` |
| 常量 | UPPER_SNAKE | `SPEED`, `MAX_HEALTH` |
| 类/场景 | PascalCase | `Player`, `Enemy` |
| 私有变量 | 前缀 `_` | `_internal_var` |

### 函数组织

```gdscript
extends Node2D

# 常量定义
const SPEED = 300.0

# 预加载资源
const ENEMY_SCENE = preload("res://scenes/enemy.tscn")

# 变量声明
var score = 0
var game_over = false

# @onready 变量
@onready var timer = $Timer
@onready var sprite = $Sprite

# 生命周期函数
func _ready():
    pass

func _process(delta):
    pass

# 自定义函数
func my_function():
    pass

# 信号处理
func _on_signal_received():
    pass
```

---

## 音效技术

### AudioStreamWAV 配置

```gdscript
var wav = AudioStreamWAV.new()
wav.set_data(byte_data)  # PackedByteArray
```

### 音频格式

| 属性 | 值 |
|------|-----|
| 采样率 | 22050 Hz |
| 格式 | 16-bit PCM |
| 声道 | 单声道 |
| 字节序 | 小端序 (Little Endian) |

---

## 性能优化

### 对象池 (未来实现)

对于频繁创建/销毁的对象（子弹、敌人），考虑使用对象池：

```gdscript
# 伪代码示例
var bullet_pool = []

func get_bullet():
    if bullet_pool.size() > 0:
        return bullet_pool.pop_back()
    return BulletScene.instantiate()

func return_bullet(bullet):
    bullet.reset()
    bullet_pool.append(bullet)
```

### 碰撞优化

- 使用 Area2D 而不是物理刚体
- 合理设置碰撞层和掩码
- 及时删除屏幕外的对象

---

## 版本控制

| 工具 | 用途 |
|------|------|
| Git | 版本控制 |
| .gitignore | Godot 特定忽略规则 |

### .gitignore 建议

```gitignore
# Godot 特定
.import/
export.cfg
export_presets.cfg

# 临时文件
*~.import
.DS_Store

# 日志
*.log
```

---

## 构建和导出

### 目标平台

| 平台 | 导出格式 |
|------|----------|
| Windows | .exe |
| macOS | .app / .dmg |
| Linux | .x86_64 |

### 导出设置 (未来配置)

```
Project → Export → 添加平台 → 配置 → 导出
```

---

## 依赖项

### 内置依赖（Godot 4.x）

- `CharacterBody2D` - 2D 角色移动
- `Area2D` - 2D 区域检测
- `AudioStreamWAV` - 音频播放
- `PackedByteArray` - 字节数组
- `PackedVector2Array` - 向量数组

### 外部依赖

**无** - 本项目不使用任何外部插件或资源

---

## 工具要求

| 工具 | 最低版本 | 推荐版本 |
|------|----------|----------|
| Godot | 4.0 | 4.2+ |
| Godot VSCode 扩展 (可选) | 最新 | 最新 |

---

**文档状态**: 进行中
**最后更新**: 2026-03-12
