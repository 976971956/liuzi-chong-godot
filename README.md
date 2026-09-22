# 六子冲 · Godot

一款使用 Godot 4.7 制作的中国民间策略棋小游戏。棋盘为横四线、竖四线的 4×4 交点，红蓝双方各六枚棋子；通过跃步抢位，形成“己—敌—己”夹击即可吃子。

## 在线试玩

发布后可在 GitHub Pages 直接游玩：

**https://976971956.github.io/liuzi-chong-godot/**

## 已实现

- 人机对战：入门、进阶、高手三档难度
- 本地双人对抗模式
- 红方玩家固定在棋盘下方，蓝方位于上方
- 横竖相邻走子、跃过一枚棋子的跃步与胜负判定
- “夹一不夹二”：形成“己—敌—己”即可吃掉中间单子，敌方对子互相保护
- 一步横竖双向围击时可以同时吃掉多枚棋子，剩两枚或无路可走即败
- 可走位置提示、上一步标记、悔棋与重新开局
- 吃子残影、冲击环与碎光飞散特效
- 胡桃木、青玉、星河漆、云纹纸四种棋盘皮肤
- 玉扣、漆雕、铜章、星环四种棋子样式
- 三套实时合成背景音乐与落子、吃子、胜利音效
- 现代国风主界面、卡片式设置与规则面板
- 四套带浮雕边缘的 2D 棋盘材质、对应场景背景图集与可拉伸 2D 按钮面板
- 统一线性矢量图标，并针对手机竖屏优化按钮尺寸、弹窗与棋盘布局
- 桌面和窄屏自适应布局，针对手机操作优化
- Godot Web 导出，可部署到静态网站

## 本地运行

1. 使用 Godot 4.7 或兼容的 Godot 4.x 打开 `godot/project.godot`。
2. 按 `F6` 或编辑器右上角运行按钮启动游戏。

## Web 导出

项目已配置名为 `Web` 的导出预设，产物位于 `docs/`。重新导出：

```bash
godot --headless --path godot --export-release Web ../docs/index.html
```

## 目录

```text
godot/                 Godot 工程
  main.tscn            主场景
  scripts/main.gd      界面与游戏状态
  scripts/ai_player.gd 人机搜索、局面评估与难度策略
  scripts/board_view.gd 棋盘绘制与交互
  scripts/sound_engine.gd 程序音乐与音效
docs/                  可直接托管的 Web 试玩版
```

字体使用 Noto Sans SC 精简字形，遵循 `godot/assets/OFL.txt` 中的 SIL Open Font License。
