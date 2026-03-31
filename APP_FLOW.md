# 雷电游戏 - 应用流程文档 (APP_FLOW)

## 屏幕/场景清单

| 屏幕 ID | 屏幕名称 | 场景文件 | 描述 |
|---------|----------|----------|------|
| SCR001 | 主菜单 | ui/main_menu.tscn | 游戏启动界面 |
| SCR002 | 游戏主场景 | main.tscn | 主要游戏画面 |
| SCR003 | 暂停界面 | (嵌入 main.tscn) | 暂停菜单 |
| SCR004 | 游戏结束界面 | (嵌入 main.tscn) | 显示游戏结束信息 |

---

## 主菜单流程 (SCR001)

### 场景结构
```
MainMenu (Control)
├── ColorRect - 深色背景
├── VBoxContainer
│   ├── TitleLabel - "雷电" 标题
│   ├── SubtitleLabel - "THUNDER FORCE"
│   └── ButtonContainer
│       ├── StartButton - 开始游戏
│       └── QuitButton - 退出游戏
└── VersionLabel - 版本号
```

### 主菜单流程
```
1. 游戏启动
   ↓
2. 显示主菜单
   ↓
3. 点击"开始游戏" → 进入游戏场景
   ↓
4. 点击"退出游戏" → 关闭程序
```

---

## 主游戏流程 (SCR002)

### 场景结构
```
Main (Node2D)
├── Player (CharacterBody2D) - 玩家飞机
├── WaveManager (Node) - 关卡波次管理
├── SoundManager (Node) - 音效管理器
├── UI (CanvasLayer) - UI 层
│   ├── TopBar - 顶部信息栏
│   │   ├── ScoreContainer - 分数显示
│   │   └── HealthContainer - 生命值图标
│   ├── WaveLabel - 关卡显示
│   ├── ComboLabel - 连击显示
│   ├── BossHealthBar - BOSS 血条
│   ├── WaveMessage - 关卡过渡提示
│   ├── WarningMessage - BOSS 警告
│   ├── BottomBar - 底部信息栏
│   │   ├── WeaponLabel - 武器等级
│   │   └── BombContainer - 炸弹数量
│   ├── GameOverOverlay - 游戏结束界面
│   └── PauseOverlay - 暂停界面
└── (动态生成的敌人、子弹、道具、BOSS)
```

### 游戏循环流程

```
1. 主菜单点击"开始游戏"
   ↓
2. 玩家飞机出现在屏幕底部中央 (240, 600)
   ↓
3. WaveManager 启动关卡 1
   ↓
4. 显示 "WAVE 1-1" 过渡动画
   ↓
5. 波次生成：每波敌人按配置循环生成
   ↓
6. 玩家控制飞机移动和射击
   ↓
7. 击毁敌人 → 分数 + 连击计数
   ↓
8. 所有波次完成后 → 生成 BOSS
   ↓
9. 显示 "WARNING!" 警告动画
   ↓
10. 击败 BOSS → 关卡完成（奖励分数）
   ↓
11. 进入下一关 或 游戏通关
   ↓
12. 生命值 = 0 → 游戏结束
```

---

## 用户输入映射

| 输入 | 动作 | 游戏内效果 |
|------|------|------------|
| W / ↑ | move_up | 飞机向上移动 |
| S / ↓ | move_down | 飞机向下移动 |
| A / ← | move_left | 飞机向左移动 |
| D / → | move_right | 飞机向右移动 |
| 空格键 | shoot | 发射子弹 |
| U 键 | use_bomb | 使用炸弹 |
| ESC | ui_cancel | 暂停游戏 / 返回主菜单 |
| 回车键 | ui_accept | 游戏结束后重新开始 |
| Q 键 | (暂停时) | 返回主菜单 |
| B 键 | spawn_test_boss | 测试：直接生成 BOSS |

---

## 暂停界面流程 (SCR003)

### 触发
- 游戏进行中按 ESC 键

### 流程
```
1. 按下 ESC 键
   ↓
2. 游戏暂停 (get_tree().paused = true)
   ↓
3. 显示暂停界面（半透明遮罩）
   ↓
4. 等待用户操作:
   - 按 ESC → 继续游戏
   - 按 Q → 返回主菜单
```

---

## 游戏结束流程 (SCR004)

### 触发
- 玩家生命值 = 0
- 或 通关所有 5 关

### 流程
```
1. 设置 game_over = true
   ↓
2. 显示游戏结束界面
   - 显示 "游戏结束" 或 "游戏通关"
   - 显示最终分数
   - 显示操作提示
   ↓
3. 等待用户操作:
   - 按回车 → 重新开始
   - 按 ESC → 返回主菜单
```

---

## UI 状态管理

### 顶部信息栏 (TopBar)

| 组件 | 显示内容 | 更新时机 |
|------|----------|----------|
| ScoreLabel | 分数数字 | 每次击杀敌人 |
| HealthIcon1-3 | 飞机图标 | 玩家受伤/恢复时 |

### 底部信息栏 (BottomBar)

| 组件 | 显示内容 | 更新时机 |
|------|----------|----------|
| WeaponLabel | "武器 Lv.X" | 武器升级时 |
| BombCount | "xX" | 使用/获得炸弹时 |

### 中间信息

| 组件 | 显示内容 | 触发条件 |
|------|----------|----------|
| WaveLabel | "WAVE X-Y" | 每波开始时 |
| ComboLabel | "COMBO xN" | 连击 ≥ 2 时 |
| BossHealthBar | 血条 + BOSS名称 | BOSS 战时 |

### 过渡动画

| 组件 | 显示内容 | 触发条件 |
|------|----------|----------|
| WaveMessage | "WAVE X-Y" | 每波开始，淡入淡出 1.3 秒 |
| WarningMessage | "WARNING!" | BOSS 登场，闪烁 3 次 |

---

## 导航图

```
[主菜单]
    ↓ 点击开始
[游戏场景] ←──────────────┐
    ↓                      │
[暂停界面] ──(ESC)────────→│
    ↓ (Q)                  │
[主菜单]                   │
                           │
[游戏结束] ──(回车)────────┘
    ↓ (ESC)
[主菜单]
```

---

## 关卡系统

### 关卡配置

| 关卡 | 波数 | BOSS | 难度 |
|------|------|------|------|
| 1 | 5 波 | 绿色战舰 | ⭐ |
| 2 | 7 波 | 红色双翼舰 | ⭐⭐ |
| 3 | 8 波 | 紫色堡垒 | ⭐⭐⭐ |
| 4 | 10 波 | 黄色蜂群 | ⭐⭐⭐⭐ |
| 5 | 12 波 | 最终 Boss | ⭐⭐⭐⭐⭐ |

### 波次流程

```
start_level(level)
    ↓
await 1 秒
    ↓
spawn_next_wave()
    ↓
生成该波敌人 (按配置)
    ↓
等待所有敌人被消灭
    ↓
check_wave_completion()
    ↓
wave_completed 信号
    ↓
下一波 或 BOSS
```

---

**文档状态**: 已更新
**最后更新**: 2026-03-31