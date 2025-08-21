import Foundation

extension APKParser {
    @discardableResult
    public func replace(displayName: String?) -> Self {
        guard let displayName = displayName else {
            return self
        }
        do {
            try ManifestBuilder(androidManifestURL)
                .replace(displayName: displayName)
                .build(to: androidManifestURL)
        }
        catch {
            debugPrint("[APKParser Replace Display Name ERROR] \(error.localizedDescription)")
        }
        return self
    }
}
