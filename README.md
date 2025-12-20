# APKParser

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SPM](https://img.shields.io/badge/SPM-Supported-green)
[![CI](https://github.com/coollazy/APKParser/actions/workflows/ci.yml/badge.svg)](https://github.com/coollazy/APKParser/actions/workflows/ci.yml)

A powerful Swift library for decompiling, modifying, and recompiling Android APK files. This library acts as a wrapper around standard Android tools (`apktool`, `zipalign`, `apksigner`), providing a clean and fluent Swift API for automating APK manipulation tasks.

## Features

- **Decompile APKs**: Extract resources and manifests using `apktool`.
- **Modify Resources**:
  - Replace Application Display Name.
  - Replace Application Package Name.
  - Replace App Icons (Launcher and Round Icons).
  - Modify String Resources.
- **Read APK Info**: Retrieve Version Code and Version Name.
- **Recompile APKs**: Build a new APK from modified sources.
- **Sign & Align**: Support for `zipalign` and `apksigner` to produce installable APKs.

## Prerequisites

This library relies on external command-line tools. Please ensure they are installed and available in your system path.

### macOS

Using [Homebrew](https://brew.sh/) is the easiest way to install dependencies on macOS.

1.  **Java (OpenJDK)**
    ```bash
    brew install openjdk
    # Follow the on-screen instructions to symlink or set JAVA_HOME
    ```

2.  **apktool**
    ```bash
    brew install apktool
    ```

3.  **Android SDK & Build-Tools**
    ```bash
    brew install --cask android-commandlinetools
    
    # Install specific build-tools (e.g., 34.0.0)
    sdkmanager "build-tools;34.0.0"
    
    # Add to PATH (in ~/.zshrc or ~/.bash_profile)
    export ANDROID_HOME="/usr/local/share/android-commandlinetools"
    export PATH="$ANDROID_HOME/build-tools/34.0.0:$PATH"
    ```

4.  **ImageMagick** (Required for Icon resizing)
    ```bash
    brew install imagemagick
    ```

### Linux (Ubuntu/Debian)

On Linux, some tools need to be installed manually.

1.  **System Dependencies**
    ```bash
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk imagemagick wget unzip
    ```

2.  **apktool**
    ```bash
    # Download wrapper script and jar
    wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
    wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O apktool.jar
    
    # Install to /usr/local/bin
    chmod +x apktool apktool.jar
    sudo mv apktool /usr/local/bin/
    sudo mv apktool.jar /usr/local/bin/
    ```

3.  **Android SDK Command Line Tools**
    ```bash
    # Create directory for SDK
    export ANDROID_HOME=$HOME/android-sdk
    mkdir -p $ANDROID_HOME/cmdline-tools
    
    # Download & Unzip
    wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline-tools.zip
    unzip cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest
    
    # Install Build-Tools
    export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
    yes | sdkmanager "build-tools;34.0.0"
    
    # Add Build-Tools to PATH
    export PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0
    ```

## Docker Support

This library supports running in Docker containers (Linux). For detailed instructions on how to set up the Docker environment and run the example project, please refer to the **[Example Project Documentation](Example/README.md)**.

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/coollazy/APKParser.git", from: "1.0.0")
]
```

## Usage

### APKParser

The `APKParser` class is the main entry point for modifying APKs.

```swift
import APKParser

// 1. Initialize Parser with the path to your APK
let apkURL = URL(fileURLWithPath: "/path/to/your.apk")
let parser = try APKParser(apkURL: apkURL)

// 2. Read Information
if let version = parser.versionWithCode() {
    print("Current Version: \(version)") // e.g., "1.0.0.100"
}

// 3. Modify APK Content
// Note: Errors in replacement methods are currently logged to console and do not halt execution.
do {
    try parser
        .replace(packageName: "com.example.newpackage")
        .replace(displayName: "My New App Name")
        .replace(iconURL: URL(fileURLWithPath: "/path/to/icon.png"))
        .replace(roundIconURL: URL(fileURLWithPath: "/path/to/round_icon.png"))
} catch {
    print("Error modifying APK: \(error)")
}

// 4. Rebuild the APK
let newApkURL = URL(fileURLWithPath: "/path/to/output.apk")
try parser.build(toPath: newApkURL)

print("APK Rebuilt at: \(newApkURL.path)")
// Note: The rebuilt APK is unsigned and cannot be installed yet.
```

### APKSigner

Use `APKSigner` to sign and align the APK so it can be installed on devices.

```swift
import APKSigner

let unsignedApkURL = URL(fileURLWithPath: "/path/to/output.apk")
let signedApkURL = URL(fileURLWithPath: "/path/to/signed_output.apk")

do {
    // Sign and Align the APK
    // If signKey is nil, a self-signed key will be generated automatically.
    try APKSigner.signature(from: unsignedApkURL, to: signedApkURL)
    
    print("Signed APK created at: \(signedApkURL.path)")
    
    // Verify Alignment
    try APKSigner.verifyAlgin(from: signedApkURL)
    
    // Verify Signature
    try APKSigner.verifySignature(from: signedApkURL)
    
} catch {
    print("Signing failed: \(error)")
}
```

## Error Handling

- **APKParser Initialization**: Throws if the APK file is not found or `apktool` fails to decompile.
- **Modifications**:
  - `replace(iconURL:)` throws specific errors like `APKParserError.invalidIconFormat` or `APKParserError.invalidIconSize`.
  - `replace(packageName:)` and `replace(displayName:)` currently catch errors internally and log them to the debug console.
- **APKSigner**: Throws if external tools (`zipalign`, `apksigner`) fail or are not found in the environment.

## License

[MIT License](LICENSE)