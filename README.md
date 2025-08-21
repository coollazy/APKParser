# APKParser

Android APK 反組譯及重新打包

## Enviorment

###Mac

***JRE***

- 安裝 JRE

	```bash
	# 安裝 OpenJDK
	brew install openjdk
	
	# 設定環境變數
	echo 'export JAVA_HOME=/opt/homebrew/opt/openjdk' >> ~/.zshrc
	echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.zshrc
	source ~/.zshrc
	```

- 驗證安裝
	
	```
	java --version
	```
	> java 22.0.1 2024-04-16
	>
	> Java(TM) SE Runtime Environment (build 22.0.1+8-16)
	>
	> Java HotSpot(TM) 64-Bit Server VM (build 22.0.1+8-16, mixed mode, sharing)

- JDK 安裝失敗，[請參考這裡](https://blog.gslin.org/archives/2022/12/28/11009/mac-%E4%B8%8A%E7%94%A8-homebrew-%E5%AE%89%E8%A3%9D-java-%E7%9A%84%E6%96%B9%E5%BC%8F/)

***apktool***

- 安裝 [apktool](https://apktool.org/docs/install)

	```
	brew install apktool
	```

- 驗證安裝

	```
	apktool --version
	```
	> 2.9.3

***Android SDK Command Line Tools 或 Android Studio***

- 安裝 Android SDK Command Line Tools 

	```bash
	# 方法 1：透過 brew cask
	brew install --cask android-commandlinetools
	
	# 設定環境變數
	echo 'export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools' >> ~/.zshrc
	echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"' >> ~/.zshrc
	echo 'export PATH="$ANDROID_HOME/build-tools/34.0.0:$PATH"' >> ~/.zshrc
	source ~/.zshrc
	
	# 安裝 build tools
	sdkmanager "build-tools;34.0.0"
	```
	
- 或是直接安裝 [Android Studio](https://developer.android.com/studio)，並啟動 Android Studio 完成安裝 Android SDK
- 驗證安裝

	```bash
	zipalign
	```
	> 
	
	```bash
	apksigner --help
	```
	>

### Linux

***JRE***

***apktool***

***Android SDK Command Line Tools 或 Android Studio***

### Docker

***JRE***

***apktool***

***Android SDK Command Line Tools 或 Android Studio***

## Usage

***Swift Package Manager***

- Package.swift 的 dependencies 內添加
	
	```swift
	.package(name: "APKParser", url: "git@gitlab.baifu-tech.net:ios/components/apkbuilder.git", from: "1.5.0"),
	```

### APKParser

- 反組譯 APK

	```swift
	// 初始化 builder
	let apkURL: URL = URL(fileURLWithPath: "your_original_apk_local_file_path")
	let parser = try APKParser(apkURL: apkURL)
	```
	
- 替換

	```swift
	// 替換 PackageName
	parser.replace(packageName: "com.coollazy.apkparser.example")
	
	// 替換 App 顯示名稱
	parser.replace(displayName: "APKParser Example")
	
	// 替換圖標
	try parser.replace(iconURL: URL(fileURLWithPath: "icon_file_path"))
	
	// 替換圓形圖標
	try parser.replace(roundIconURL: URL(fileURLWithPath: "round_icon_file_path"))
	```

- 重新打包

	```swift
	// 產生新 APK
	let newApkURL: URL = URL(fileURLWithPath: "new_apk_file_path")
	try parser.build(toPath: newApkURL)
	```
	> 產生出來的 APK 若有修改內容，無法直接安裝到手機上
	>
	> 需要額外簽名才能安裝
	
## 參考指令

***Decode & Encode APK***

- Decode apk to folder with apktool

	```sh
	apktool d -f /path/from/APK -o /path/to/decoded/folder
	```

- Encode folder to apk with apktool

	```sh
	apktool b /path/to/decoded/folder -o /path/to/new-apk
	```

***Signature APK***

- Align apk

	```sh
	apktool b /path/to/decoded/folder -o /path/to/new-apk
	```

- Signature apk
	
	```sh
	apktool b /path/to/decoded/folder -o /path/to/new-apk
	```


