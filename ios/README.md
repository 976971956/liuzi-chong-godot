# 六子冲 iOS 工程

这个目录是 Godot iOS 导出工程的结构和启动代码。仓库不保存 Godot 导出的 `.a`/`.xcframework` 和 `.pck` 大文件；在 macOS 上安装 Godot 4.7.1、iOS export templates 和 Xcode 后，从项目根目录运行：

```bash
./scripts/export-ios.sh
```

脚本会在 `build/ios/` 生成完整的 `LiuziChong.xcodeproj`。打开工程后，在 Xcode 的 Signing & Capabilities 中选择自己的 Apple Team 和签名方式，再运行到 iPhone 或 iOS Simulator。`godot/export_presets.cfg` 已设置 bundle identifier、图标和启动画面参数；发布到设备或 App Store 前请替换其中的 Team ID。
