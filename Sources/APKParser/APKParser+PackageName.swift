import Foundation

extension APKParser {
    @discardableResult
    public func replace(packageName: String?) -> Self {
        guard let packageName = packageName else {
            return self
        }
        
        do {
            try ManifestBuilder(androidManifestURL)
                .replace(packageName: packageName)
                .build(to: androidManifestURL)
            
            let content = try String(contentsOf: apktoolYamlURL)
            let newContent = content.replacingOccurrences(of: "renameManifestPackage: null", with: "renameManifestPackage: \(packageName)")
            try newContent.write(to: apktoolYamlURL, atomically: true, encoding: .utf8)
        }
        catch {
            debugPrint("[APKParser Replace Package Name ERROR] \(error.localizedDescription)")
        }
        return self
    }
}
