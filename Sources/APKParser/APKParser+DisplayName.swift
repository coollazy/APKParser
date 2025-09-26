import Foundation

extension APKParser {
    @discardableResult
    public func replace(displayName: String?) -> Self {
        guard let displayName = displayName else {
            return self
        }
        do {
            try StringsBuilder(stringsURL)
                .replace(displayName: displayName)
                .build(to: stringsURL)
        }
        catch {
            debugPrint("[APKParser Replace Display Name ERROR] \(error.localizedDescription)")
        }
        return self
    }
}
