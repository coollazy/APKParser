import Foundation
import APKParser
import APKSigner

// 原始APK檔案位置
let apkURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
    .appendingPathComponent("test.apk")

// 生成APK檔案位置
let newApkURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("apks")
    .appendingPathComponent("new.apk")

// 方形圖標檔案位置
let iconURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
    .appendingPathComponent("icon.png")

// 圓型檔案位置
let roundIconURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
    .appendingPathComponent("icon-round.png")

do {
    // 驗證Align
    try APKSigner.verifyAlgin(from: apkURL)
    print("APKSigner verify zipAlgin successfully! ✅")
}
catch {
    print("❌❌ APKSigner verify zipAlgin failed => \(error.localizedDescription)")
    exit(1)
}

do {
    // 驗證Signature
    try APKSigner.verifySignature(from: apkURL)
    print("APKSigner verify signature successfully! ✅")
}
catch {
    print("❌❌ APKSigner verify Signature failed => \(error.localizedDescription)")
    exit(1)
}

do {
    // 反組譯 APK 並替換部分資訊
    let parser = try APKParser(apkURL: apkURL)
        .replace(packageName: "com.coollazy.apkparser.example")
        .replace(displayName: "APKParser Example")
        .replace(iconURL: iconURL)
        .replace(roundIconURL: roundIconURL)
    print("APK Version => \(parser.version() ?? "**")")
    
    // 重新打包 APK
    try parser.build(toPath: newApkURL)
    print("APKParser build new apk successfully! ✅ => \(newApkURL)")
    
    // APK 簽名
    try APKSigner.signature(from: newApkURL, to: newApkURL)
    print("APKParser signature apk successfully! ✅ => \(newApkURL)")
}
catch {
    print("❌❌ \(error.localizedDescription)")
    exit(1)
}
