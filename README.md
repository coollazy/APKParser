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

### 1. Java Runtime Environment (JRE)

`apktool` requires Java.

```bash
# Install OpenJDK via Homebrew
brew install openjdk

# Set environment variables (Example for zsh)
echo 'export JAVA_HOME=/opt/homebrew/opt/openjdk' >> ~/.zshrc
echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
java --version
```

### 2. apktool

Required for decompiling and building APKs.

```bash
# Install apktool via Homebrew
brew install apktool

# Verify installation
apktool --version
```

### 3. Android SDK Build-Tools

Required for `zipalign` and `apksigner`.

```bash
# Install Android Command Line Tools via Homebrew
brew install --cask android-commandlinetools

# Install specific build-tools (e.g., 34.0.0)
sdkmanager "build-tools;34.0.0"

# Set environment variables
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH="$ANDROID_HOME/build-tools/34.0.0:$PATH"
```

Alternatively, if you have **Android Studio** installed, ensure `$ANDROID_HOME/build-tools/<version>/` is in your `PATH`.

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
    // Replace Package Name
    parser.replace(packageName: "com.example.newpackage")
    
    // Replace Display Name
    parser.replace(displayName: "My New App Name")
    
    // Replace Icon
    try parser.replace(iconURL: URL(fileURLWithPath: "/path/to/icon.png"))
    
    // Replace Round Icon
    try parser.replace(roundIconURL: URL(fileURLWithPath: "/path/to/round_icon.png"))
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