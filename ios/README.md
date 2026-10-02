# 六子冲 iOS 工程

这个目录是 Godot iOS 导出工程的结构和启动代码。仓库不保存 Godot 导出的 `.a`/`.xcframework` 和 `.pck` 大文件；在 macOS 上安装 Godot 4.7.1、iOS export templates 和 Xcode 后，从项目根目录运行：

```bash
./scripts/export-ios.sh
```

脚本会在 `build/ios/` 生成完整的 `LiuziChong.xcodeproj`。打开工程后，在 Xcode 的 Signing & Capabilities 中选择自己的 Apple Team 和签名方式，再运行到 iPhone 或 iOS Simulator。`godot/export_presets.cfg` 已设置 bundle identifier、图标和启动画面参数，仓库内工程默认使用团队 `BYSMY792J7`。

如果已经有仓库内的 iOS 工程，可以直接归档并导出开发版 IPA：

```bash
./scripts/package-ios.sh
```

脚本默认使用 `BYSMY792J7` 和本机的 `Apple Development` 证书，也可以通过 `IOS_TEAM_ID`、`IOS_SIGNING_IDENTITY` 和 `IOS_CONFIGURATION` 覆盖。导出的文件位于 `build/ios/ipa/LiuziChong.ipa`。把 iPhone 解锁并信任这台 Mac 后，在 Xcode 里选择设备运行，或使用 `xcrun devicectl device install app --device <设备UDID> build/ios/ipa/LiuziChong.ipa` 安装。
