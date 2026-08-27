# 六子冲 · Godot

一款使用 Godot 4.7 制作的中国民间策略棋小游戏。棋盘为四竖五横，红蓝双方各六枚棋子；主动形成连续的“己—己—敌”活枪即可吃子。

## 在线试玩

发布后可在 GitHub Pages 直接游玩：

**https://976971956.github.io/liuzi-chong-godot/**

## 已实现

- 人机对战：入门、进阶、高手三档难度
- 本地双人对抗模式
- 红方玩家固定在棋盘下方，蓝方位于上方
- 相邻横竖走子、活枪吃子与胜负判定
- 同色两子处在同一条横线或竖线上时相互保护，不能被吃
- 可走位置提示、上一步标记、悔棋与重新开局
- 吃子残影、冲击环与碎光飞散特效
- 胡桃木、青玉、星河漆、云纹纸四种棋盘皮肤
- 玉扣、漆雕、铜章、星环四种棋子样式
- 三套实时合成背景音乐与落子、吃子、胜利音效
- 桌面和窄屏自适应布局
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
