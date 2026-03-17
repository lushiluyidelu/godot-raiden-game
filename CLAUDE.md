# CLAUDE.md - 雷电游戏项目开发指南

## 项目概述

这是一个类似雷电的 2D 垂直滚动射击游戏，使用 Godot 4.x 和 GDScript 开发。

**核心玩法**: 玩家控制飞机移动和射击，击毁从屏幕上方出现的敌机，获得分数。

---

## 技术栈摘要

| 组件 | 技术 |
|------|------|
| 引擎 | Godot 4.x |
| 语言 | GDScript 2.0 |
| 分辨率 | 480x720 (竖版) |
| 渲染器 | Compatibility |

---

## 项目结构

```
game/
├── scenes/
│   ├── main.tscn          # 主游戏场景
│   ├── player.tscn        # 玩家飞机
│   ├── enemy.tscn         # 敌人
│   └── bullet.tscn        # 子弹
├── scripts/
│   ├── main.gd            # 主场景逻辑
│   ├── player.gd          # 玩家控制
│   ├── enemy.gd           # 敌人逻辑
│   ├── bullet.gd          # 子弹逻辑
│   └── sound_manager.gd   # 音效管理
└── assets/
    └── sprites/
```

---

## 代码规范

### 命名约定
- 变量/函数：`snake_case`
- 常量：`UPPER_SNAKE_CASE`
- 私有变量：前缀 `_`

### 文件头格式
```gdscript
extends Node2D

const SPEED = 300.0
@onready var sprite = $Sprite

func _ready():
    pass

func _process(delta):
    pass
```

---

## 碰撞层配置

```
Layer 1: player
Layer 2: bullets
Layer 3: enemies
```

| 对象 | Layer | Mask |
|------|-------|------|
| 玩家 | 1 | 3 |
| 子弹 | 2 | 3 |
| 敌人 | 3 | 2 |

---

## 输入映射

- `move_up`: W / ↑
- `move_down`: S / ↓
- `move_left`: A / ←
- `move_right`: D / →
- `shoot`: 空格键 / 鼠标左键

---

## 当前进度

**阶段 5**: 游戏完整性 ✅ 完成

**已完成**:
- ✅ 玩家控制、射击
- ✅ 敌人生成、移动
- ✅ 碰撞检测
- ✅ 分数系统
- ✅ 视觉改进（飞机图形、星空背景）
- ✅ 音效系统（射击、爆炸、BGM）
- ✅ 生命值系统（3 点生命，无敌时间）
- ✅ 游戏结束界面（回车键重新开始）

**下一步**:
1. 爆炸粒子特效（阶段 6）
2. 主菜单界面（阶段 7）
3. 高分系统（阶段 7）

---

## 关键实现细节

### 玩家飞机 (player.gd)
- CharacterBody2D + Sprite2D + CollisionShape2D
- 移动速度：300
- 射击间隔：0.15 秒

### 敌人 (enemy.gd)
- Area2D + Sprite2D + CollisionShape2D
- 移动速度：60
- 生命值：1
- 生成间隔：1 秒

### 子弹 (bullet.gd)
- Area2D + Sprite2D + CollisionShape2D
- 飞行速度：600
- 伤害：1

### 音效 (sound_manager.gd)
- 使用 AudioStreamWAV 程序化生成音频
- 采样率：22050 Hz
- 16-bit PCM 格式

---

## 允许的操作

- ✅ 修改现有脚本和场景
- ✅ 添加新功能和特效
- ✅ 调整游戏平衡参数
- ✅ 创建新场景和脚本

## 禁止的操作

- ❌ 删除已有功能（除非替换为更好的实现）
- ❌ 修改项目核心配置（分辨率、渲染器）
- ❌ 添加外部依赖/插件

---

## 调试命令

运行游戏：按 F5
停止游戏：按 F8
查看输出：底部面板 → Output

---

## 常见问题修复

### 碰撞检测不工作
检查碰撞层和掩码设置是否正确

### 音效不播放
检查 AudioStreamWAV.set_data() 使用 PackedByteArray

### 场景加载失败
检查文件路径是否正确 (res://)

---

**最后更新**: 2026-03-12
