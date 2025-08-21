import Foundation
import APKParser

// 原始APK檔案位置
let apkURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
    .appendingPathComponent("test.apk")

// 生成APK檔案位置
let newApkURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("apks")
    .appendingPathComponent("new.apk")

// 生成APK檔案位置
let iconURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
    .appendingPathComponent("icon.png")

// 生成APK檔案位置
let roundIconURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
    .appendingPathComponent("icon-round.png")

// 簽名金鑰
let signKeyURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
    .appendingPathComponent("AndoirdSignKey.jks")

do {
    let parser = try APKParser(apkURL: apkURL)
        .replace(packageName: "com.coollazy.apkparser.example")
        .replace(displayName: "APKParser Example")
        .replace(iconURL: iconURL)
        .replace(roundIconURL: roundIconURL)
    
    print("APK Version => \(parser.version() ?? "**")")
    
    try parser.build(toPath: newApkURL)
    
    print("APKParser build new apk successfully! => \(newApkURL)")
}
catch {
    print("APKParser error => \(error.localizedDescription)")
}
