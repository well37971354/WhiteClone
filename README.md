# LilyWhite — Status Bar Capsule Tweak

> Your whole status bar in one clean capsule.

参考 [Lilywhite](https://havoc.app/package/lilywhite) 的概念，为 iOS 16+ 越狱设备开发的状态栏胶囊美化插件（rootless 版本）。

## 功能

- 将整个状态栏包裹进一个圆角胶囊造型
- 胶囊颜色可自定义（默认纯黑半透明）
- 透明度可调节
- 圆角半径可调节
- 左右 / 上下边距可调节
- rootless 兼容（适用于 iOS 17 / iPhone 15，Dopamine / Taurine / XinaA5 等越狱环境）
- 偏好修改后实时生效

## 工程结构

```
LilyWhiteClone/
├── Makefile              # Theos 编译配置
├── control               # deb 包元信息
├── Tweak.x               # 核心 hook 逻辑
├── LilyWhite.plist       # 进程 filter（只注入 SpringBoard）
└── README.md
```

## 编译方法

需要在 macOS 或 Linux 环境下安装 Theos：

```bash
# 1. 确保已安装 Theos 并配置好 toolchain
export THEOS=~/theos

# 2. 进入工程目录
cd LilyWhiteClone

# 3. 编译打包
make package

# 产物位于：
# .packages/com.lilywhite.clone_1.0.0_iphoneos-arm64.deb
```

## 安装

将编译好的 `.deb` 文件通过 Sileo / Zebra / Filza 安装到越狱设备，安装后注销 SpringBoard 即可看到效果。

## 偏好配置

插件默认开箱即用，无需配置。如需自定义，可通过以下 plist 文件修改偏好：

**路径：** `/var/jb/var/mobile/Library/Preferences/com.lilywhite.clone.plist`

| 键名 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `LWEnabled` | Bool | `true` | 总开关 |
| `LWCapsuleColor` | String | `#000000` | 胶囊颜色（hex） |
| `LWAlpha` | Float | `0.35` | 透明度 0~1 |
| `LWCornerRadius` | Float | `17.0` | 圆角半径（pt） |
| `LWMarginX` | Float | `8.0` | 左右边距（pt） |
| `LWMarginY` | Float | `4.0` | 上下边距（pt） |

修改后发送通知触发刷新：

```bash
notifyutil -p com.lilywhite.clone.preferences-changed
```

## 兼容性

- iOS 16.0 ~ iOS 17.x
- arm64 / arm64e（iPhone 15 Pro 等 A17 Pro 设备）
- Rootless 越狱（Dopamine / Taurine 2 / XinaA5 / palera1n rootless）

## 备注

本项目是基于公开页面描述 "Your whole status bar in one clean capsule" 开发的概念复刻版。原版 Lilywhite 由 tako3s 开发，售价 $2.49，更多细节请参考原版页面。
