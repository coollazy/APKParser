import Foundation
import Command

public class APKParser {
    let apkURL: URL

    /// Builder 自動生成的檔案存放路徑
    private var workingDirectory: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("APKParser")
        .appendingPathComponent(UUID().uuidString)
    
    /// 解壓後的APK內容檔案位置
    public var appDirectory: URL {
        workingDirectory.appendingPathComponent("apk")
    }

    public init(apkURL: URL) throws {
        guard FileManager.default.fileExists(atPath: apkURL.path) else {
            throw APKParserError.templateAPKNotFound(apkURL.path)
        }
        self.apkURL = apkURL
        
        try Command.run("apktool", arguments: [
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

    /// 重新打包 APK，將 appDirectory 路徑下的檔案打包成新的 APK 存到指定的路徑
    public func build(toPath: URL) throws {
        try Command.run("apktool", arguments: [
            "b", appDirectory.path,
            "-o", toPath.path,
        ])
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
