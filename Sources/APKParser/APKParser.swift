import Foundation
import Command

/// A Swift wrapper around `apktool` for decoding, modifying, and rebuilding Android APK files.
///
/// `APKParser` handles the unpacking of an APK file into a temporary directory, allows modifications
/// to resources (manifest, strings, icons), and rebuilds the APK. It manages the lifecycle of
/// temporary files, ensuring cleanup upon deinitialization.
public class APKParser {
    let apkURL: URL
    private let commandRunner: CommandRunner

    /// The temporary directory where the APK is unpacked and processed.
    private var workingDirectory: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("APKParser")
        .appendingPathComponent(UUID().uuidString)
    
    /// The directory containing the decoded APK content.
    public var appDirectory: URL {
        workingDirectory.appendingPathComponent("apk")
    }

    /// Initializes a new `APKParser` instance and decodes the specified APK.
    ///
    /// This initializer runs `apktool d` to decode the APK into a temporary directory.
    ///
    /// - Parameters:
    ///   - apkURL: The file URL of the APK to be parsed.
    ///   - commandRunner: The command runner used to execute shell commands. Defaults to `ShellCommandRunner`.
    /// - Throws: `APKParserError.templateAPKNotFound` if the APK file does not exist, or other errors if `apktool` fails.
    public init(apkURL: URL, commandRunner: CommandRunner = ShellCommandRunner()) throws {
        guard FileManager.default.fileExists(atPath: apkURL.path) else {
            throw APKParserError.templateAPKNotFound(apkURL.path)
        }
        self.apkURL = apkURL
        self.commandRunner = commandRunner
        
        try commandRunner.run("apktool", arguments: [
            "d",
            "-f", apkURL.path,
            "-o", appDirectory.path,
        ])
    }

    deinit {
        do {
            try FileManager.default.removeItem(atPath: workingDirectory.path)
        }
        catch {
            debugPrint("[APKParser Clear ERROR] \(error.localizedDescription)")
        }
    }

    /// Rebuilds the APK from the modified resources.
    ///
    /// This method runs `apktool b` to package the contents of `appDirectory` into a new APK file.
    /// The build is performed to a temporary file first, verified for integrity, and moved to `toPath` only upon success.
    ///
    /// - Parameter toPath: The destination file URL for the new APK.
    /// - Throws: An error if `apktool` fails to build the APK or if the resulting file is corrupted.
    public func build(toPath: URL) throws {
        let tempBuildURL = workingDirectory.appendingPathComponent("temp_build.apk")
        
        // 1. Build to temporary file
        try commandRunner.run("apktool", arguments: [
            "b", appDirectory.path,
            "-o", tempBuildURL.path,
        ])
        
        // 2. Verify APK integrity using zipinfo (fast check)
        // If zipinfo fails (returns non-zero), commandRunner will throw
        do {
            try commandRunner.run("zipinfo", arguments: ["-t", tempBuildURL.path])
        } catch {
            throw APKParserError.apkVerificationFailed(tempBuildURL.path)
        }
        
        // 3. Move to final destination
        if FileManager.default.fileExists(atPath: toPath.path) {
            try FileManager.default.removeItem(at: toPath)
        }
        
        // Ensure the destination directory exists
        let destinationDir = toPath.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: destinationDir.path) {
            try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        }
        
        try FileManager.default.moveItem(at: tempBuildURL, to: toPath)
    }
}

extension APKParser {
    /// 解壓後的 APK 的 `AndroidManifest.xml`
    public var androidManifestURL: URL {
        appDirectory.appendingPathComponent("AndroidManifest.xml")
    }
    
    public var apktoolYamlURL: URL {
        appDirectory.appendingPathComponent("apktool.yml")
    }
    
    /// 解壓後的 APK 的 `res` 資料夾
    public var resDirectory: URL {
        appDirectory.appendingPathComponent("res")
    }
    
    /// 解壓後的 APK 的 `assets` 資料夾
    public var assetsDirectory: URL {
        appDirectory.appendingPathComponent("assets")
    }
    
    public var stringsURL: URL {
        appDirectory
            .appendingPathComponent("res")
            .appendingPathComponent("values")
            .appendingPathComponent("strings")
            .appendingPathExtension("xml")
    }
}
