# APKParser

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SPM](https://img.shields.io/badge/SPM-Supported-green)
[![CI](https://github.com/coollazy/APKParser/actions/workflows/ci.yml/badge.svg)](https://github.com/coollazy/APKParser/actions/workflows/ci.yml)

一個功能強大的 Swift 函式庫，用於反組譯、修改和重新打包 Android APK 檔案。此函式庫作為標準 Android 工具（`apktool`、`zipalign`、`apksigner`）的封裝器，提供簡潔流暢的 Swift API，讓您可以輕鬆自動化 APK 的處理任務。

[English Documentation](README.md)

## 功能特性

- **反組譯 APK**：使用 `apktool` 提取資源和 Manifest 檔案。
- **修改資源**：
  - 替換應用程式顯示名稱 (Display Name)。
  - 替換應用程式套件名稱 (Package Name)。
  - 替換 App 圖標（包含啟動圖標和圓形圖標）。
  - 修改字串資源 (Strings)。
- **讀取 APK 資訊**：取得版本代碼 (Version Code) 和版本名稱 (Version Name)。
- **重新打包 APK**：將修改後的資源重新打包成新的 APK。
- **簽名與對齊**：支援 `zipalign` 和 `apksigner`，產生可安裝的 APK 檔案。

## 環境需求

此函式庫依賴外部命令行工具。請確保您的系統路徑中已安裝並可存取這些工具。

### macOS

使用 [Homebrew](https://brew.sh/) 是在 macOS 上安裝依賴最簡單的方式。

1.  **Java (OpenJDK)**

    ```bash
    brew install openjdk
    # 請依照螢幕上的指示設定 JAVA_HOME
    ```

2.  **apktool**
    
    ```bash
    brew install apktool
    ```

3.  **Android SDK & Build-Tools**
    
    ```bash
    brew install --cask android-commandlinetools
    
    # 安裝特定版本的 build-tools (例如 34.0.0)
    sdkmanager "build-tools;34.0.0"
    
    # 將其加入 PATH (在 ~/.zshrc 或 ~/.bash_profile)
    export ANDROID_HOME="/usr/local/share/android-commandlinetools"
    export PATH="$ANDROID_HOME/build-tools/34.0.0:$PATH"
    ```

4.  **ImageMagick** (調整圖標大小所需)
    
    ```bash
    brew install imagemagick
    ```

### Linux (Ubuntu/Debian)

在 Linux 上，部分工具需要手動安裝。

1.  **系統依賴**
    
    ```bash
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk imagemagick wget unzip
    ```

2.  **apktool**
    
    ```bash
    # 下載啟動腳本與 jar 檔
    wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
    wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O apktool.jar
    
    # 安裝至 /usr/local/bin
    chmod +x apktool apktool.jar
    sudo mv apktool /usr/local/bin/
    sudo mv apktool.jar /usr/local/bin/
    ```

3.  **Android SDK Command Line Tools**
    
    ```bash
    # 建立 SDK 目錄
    export ANDROID_HOME=$HOME/android-sdk
    mkdir -p $ANDROID_HOME/cmdline-tools
    
    # 下載並解壓縮
    wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline-tools.zip
    unzip cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest
    
    # 安裝 Build-Tools
    export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
    yes | sdkmanager "build-tools;34.0.0"
    
    # 將 Build-Tools 加入 PATH
    export PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0
    ```

## Docker 支援

本函式庫支援在 Docker 容器 (Linux) 中運行。關於如何設置 Docker 環境及運行範例專案的詳細說明，請參考 **[範例專案文件](Example/README.md)**。

## 安裝

### Swift Package Manager

在您的 `Package.swift` 中添加依賴：

```swift
dependencies: [
    .package(url: "https://github.com/coollazy/APKParser.git", from: "1.1.2")
]
```

## 使用指南

### APKParser

`APKParser` 類別是修改 APK 的主要入口點。

```swift
import APKParser

// 1. 初始化 Parser 並指定 APK 路徑
let apkURL = URL(fileURLWithPath: "/path/to/your.apk")
let parser = try APKParser(apkURL: apkURL)

// 2. 讀取資訊
if let version = parser.versionWithCode() {
    print("當前版本: \(version)") // 例如: "1.0.0.100"
}

// 3. 修改 APK 內容
// 注意: 替換方法中的錯誤目前會記錄到控制台 (console)，不會中斷執行。
do {
    try parser
        .replace(packageName: "com.example.newpackage")
        .replace(displayName: "My New App Name")
        .replace(iconURL: URL(fileURLWithPath: "/path/to/icon.png"))
        .replace(roundIconURL: URL(fileURLWithPath: "/path/to/round_icon.png"))
} catch {
    print("修改 APK 時發生錯誤: \(error)")
}

// 4. 重新打包 APK
let newApkURL = URL(fileURLWithPath: "/path/to/output.apk")
try parser.build(toPath: newApkURL)

print("APK 已重新打包至: \(newApkURL.path)")
// 注意: 重新打包後的 APK 尚未簽名，無法直接安裝。
```

### APKSigner

使用 `APKSigner` 對 APK 進行簽名和對齊，使其可安裝到裝置上。

```swift
import APKSigner

let unsignedApkURL = URL(fileURLWithPath: "/path/to/output.apk")
let signedApkURL = URL(fileURLWithPath: "/path/to/signed_output.apk")

do {
    // 簽名並對齊 APK
    // 如果 signKey 為 nil，將自動產生一組自簽名金鑰。
    try APKSigner.signature(from: unsignedApkURL, to: signedApkURL)
    
    print("已簽名 APK 產生於: \(signedApkURL.path)")
    
    // 驗證對齊狀態
    try APKSigner.verifyAlgin(from: signedApkURL)
    
    // 驗證簽名狀態
    try APKSigner.verifySignature(from: signedApkURL)
    
} catch {
    print("簽名失敗: \(error)")
}
```

## 錯誤處理

- **APKParser 初始化**：如果找不到 APK 檔案或 `apktool` 反組譯失敗，將拋出錯誤。
- **修改操作**：
  - `replace(iconURL:)` 會拋出特定錯誤，如 `APKParserError.invalidIconFormat` 或 `APKParserError.invalidIconSize`。
  - `replace(packageName:)` 和 `replace(displayName:)` 目前會在內部捕獲錯誤並將其記錄到 debug console。
- **APKSigner**：如果外部工具（`zipalign`、`apksigner`）執行失敗或在環境變數中找不到，將拋出錯誤。

## License

[MIT License](LICENSE)
