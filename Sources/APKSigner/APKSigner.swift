import Foundation
import APKSignKey
import Command

public enum APKSigner {
    /// 簽名(包含對齊)
    public static func signature(from fromApkURL: URL, to toApkURL: URL, signKey: APKSignKey? = nil) throws {
        let workingDirectory: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("APKSigner")
            .appendingPathComponent(UUID().uuidString)
        
        if FileManager.default.fileExists(atPath: workingDirectory.path) == false {
            try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        
        // Signature
        let signedURL = workingDirectory.appendingPathComponent("signed.apk")
        let password = String.randomPassword()
        let signatureKey = try signKey ?? APKSignKey.generateKey(name: UUID().uuidString, password: password, storePassword: password)
        try Command.run(
            "apksigner",
            arguments: [
                "sign",
                "--ks", signatureKey.url.path,
                "--ks-key-alias", signatureKey.name,
                "--ks-pass", "pass:\(signatureKey.storePassword)",
                "--key-pass", "pass:\(signatureKey.password)",
                "--out", signedURL.path,
                fromApkURL.path,
            ],
            environment: androidBuildToolEnvironmentVariable(),
            logEnable: true
        )
        
        
        // Algin(必要步驟，否則會無法安裝 APK)
        let alignedURL = workingDirectory.appendingPathComponent("aligned.apk")
        try Command.run(
            "zipalign",
            arguments: [
                "-v",
                "-p", "4",
                signedURL.path,
                alignedURL.path,
            ],
            environment: androidBuildToolEnvironmentVariable()
        )
        
        
        // 把暫存檔，移動到指定的位置
        if FileManager.default.fileExists(atPath: toApkURL.deletingLastPathComponent().path) == false {
            // 自動建立路徑
            try FileManager.default.createDirectory(at: toApkURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        if FileManager.default.fileExists(atPath: toApkURL.path) {
            // 自動刪除已存在的檔案
            try FileManager.default.removeItem(at: toApkURL)
        }
        try FileManager.default.moveItem(at: alignedURL, to: toApkURL)
        
        
        // 清除暫存檔
        defer {
            do {
                try FileManager.default.removeItem(atPath: workingDirectory.path)
            }
            catch {
                debugPrint("APKSigner clear temp directory error: \(error.localizedDescription)")
            }
        }
    }
    
    /// 驗證 APK 是否已經對齊
    public static func verifyAlgin(from apkURL: URL) throws {
        try Command.run(
            "zipalign",
            arguments: [
                "-c",
                "-v",
                "4",
                apkURL.path,
            ],
            environment: androidBuildToolEnvironmentVariable()
        )
    }
    
    /// 驗證APK是否已經簽名
    public static func verifySignature(from apkURL: URL) throws {
        try Command.run(
            "apksigner",
            arguments: [
                "verify",
                "--verbose",
                "--print-certs",
                apkURL.path,
            ],
            environment: androidBuildToolEnvironmentVariable()
        )
    }
}

// MARK: 取得 android build tool 最新版本的路徑
extension APKSigner {
    private static func androidBuildToolEnvironmentVariable() -> [String: String] {
        let androidHome = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Android/sdk").path
        
        var environment = [String: String]()
        if let androidBuildToolsPath = latestAndroidBuildToolsPath() {
            environment = [
                "ANDROID_HOME": androidHome,
                "PATH": "\(androidBuildToolsPath):" + (ProcessInfo.processInfo.environment["PATH"] ?? "")
            ]
        }
        
        return environment
    }
        
    private static func latestAndroidBuildToolsPath() -> String? {
        let androidHome = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Android/sdk").path
        let buildToolsDir = androidHome + "/build-tools"

        guard let subdirs = try? FileManager.default.contentsOfDirectory(atPath: buildToolsDir) else {
            return nil
        }

        // 過濾出合法的版本資料夾 (例如 "34.0.0")
        let versions = subdirs.filter { $0.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) != nil }

        // 取最新版本
        let latest = versions.sorted { v1, v2 in
            let p1 = v1.split(separator: ".").compactMap { Int($0) }
            let p2 = v2.split(separator: ".").compactMap { Int($0) }
            return p1.lexicographicallyPrecedes(p2) == false
        }.first

        if let latest {
            return "\(buildToolsDir)/\(latest)"
        }
        return nil
    }
}

// MARK: - 產生隨機密碼
extension String {
    static func randomPassword(length: Int = 12) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
        return String((0..<length).map { _ in
            characters.randomElement()!
        })
    }
}
