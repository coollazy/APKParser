import Foundation

public extension ManifestBuilder {
    func replace(displayName: String?) -> Self {
        guard let displayName = displayName else {
            return self
        }
        let applications = applications
        guard applications.count > .zero else {
            return self
        }
        let application = applications[.zero]
        let attribute = application.attribute(forName: "android:label")
        attribute?.stringValue = displayName
        return self
    }
}
