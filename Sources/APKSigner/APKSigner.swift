import Foundation
import APKSignKey
import Command

/// A utility for signing and verifying Android APKs.
///
/// `APKSigner` provides wrappers around the `zipalign` and `apksigner` command-line tools.
/// It supports aligning APKs (zip-align), signing them with a keystore, and verifying existing signatures.
public enum APKSigner {
    
    /// Signs an APK file.
    ///
    /// This process involves two steps:
    /// 1.  **Alignment**: Runs `zipalign` on the input APK to optimize it.
    /// 2.  **Signing**: Runs `apksigner` using the provided or generated key.
    ///
    /// - Parameters:
    ///   - fromApkURL: The file URL of the input (unsigned or existing) APK.
    ///   - toApkURL: The destination file URL for the signed and aligned APK.
    ///   - signKey: The signing key configuration. If `nil`, a random key is generated.
    ///   - commandRunner: The runner for executing shell commands. Defaults to `ShellCommandRunner`.
    /// - Throws: An error if `zipalign` or `apksigner` commands fail, or if file operations fail.
    public static func signature(from fromApkURL: URL, to toApkURL: URL, signKey: APKSignKey? = nil, commandRunner: CommandRunner = ShellCommandRunner()) throws {
        let workingDirectory: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("APKSigner")
            .appendingPathComponent(UUID().uuidString)
        
        if FileManager.default.fileExists(atPath: workingDirectory.path) == false {
            try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        // 清除暫存檔
        defer {
            do {
                try FileManager.default.removeItem(atPath: workingDirectory.path)
            }
            catch {
                debugPrint("APKSigner clear temp directory error: \(error.localizedDescription)")
            }
        }
        
        
        // Algin(必要步驟，否則會無法安裝 APK)
        let alignedURL = workingDirectory.appendingPathComponent("aligned.apk")
        try commandRunner.run(
            "zipalign",
            arguments: [
                "-v",
                "-p", "4",
                fromApkURL.path,
                alignedURL.path,
            ],
            environment: androidBuildToolEnvironmentVariable()
        )
        
        
        // Signature
        let signedURL = workingDirectory.appendingPathComponent("signed.apk")
        let password = String.randomPassword()
        let signatureKey = try signKey ?? APKSignKey.generateKey(name: UUID().uuidString, password: password, storePassword: password)
        try commandRunner.run(
            "apksigner",
            arguments: [
                "sign",
                "--ks", signatureKey.url.path,
                "--ks-key-alias", signatureKey.name,
                "--ks-pass", "pass:\(signatureKey.storePassword)",
                "--key-pass", "pass:\(signatureKey.password)",
                "--out", signedURL.path,
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
        try FileManager.default.moveItem(at: signedURL, to: toApkURL)
    }
    
    /// Verifies if an APK is zip-aligned.
    ///
    /// Runs `zipalign -c` to check alignment.
    ///
    /// - Parameters:
    ///   - apkURL: The file URL of the APK to verify.
    ///   - commandRunner: The runner for executing shell commands. Defaults to `ShellCommandRunner`.
    /// - Throws: An error if the verification command fails (indicating the APK is not aligned) or if the tool execution fails.
    public static func verifyAlgin(from apkURL: URL, commandRunner: CommandRunner = ShellCommandRunner()) throws {
        try commandRunner.run(
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
    
    /// Verifies the signature of an APK.
    ///
    /// Runs `apksigner verify` to check the signature validity.
    ///
    /// - Parameters:
    ///   - apkURL: The file URL of the APK to verify.
    ///   - commandRunner: The runner for executing shell commands. Defaults to `ShellCommandRunner`.
    /// - Throws: An error if the verification command fails (indicating the APK signature is invalid) or if the tool execution fails.
    public static func verifySignature(from apkURL: URL, commandRunner: CommandRunner = ShellCommandRunner()) throws {
        try commandRunner.run(
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
