import Foundation

public extension ManifestBuilder {
    func replace(packageName: String?) -> Self {
        guard let packageName = packageName else {
            return self
        }
        let rootElement = xml.rootElement()
        let attribute = rootElement?.attribute(forName: "package")
        
        /// 保留原本的 packageName 整個檔案內有相同名字的都要取代掉
        if let currentPackageName = attribute?.stringValue {
            replaceElement(packageName: currentPackageName, with: packageName, element: rootElement)
        }
        return self
    }
}

private extension ManifestBuilder {
    private func replaceElement(packageName: String, with newPackageName: String, element: XMLElement?) {
        guard let element = element else {
            return
        }
        for attribute in element.attributes ?? [] {
            attribute.stringValue = attribute.stringValue?.replacingOccurrences(of: packageName, with: newPackageName)
        }
        for child in element.children ?? [] {
            if let childElement = child as? XMLElement {
                replaceElement(packageName: packageName, with: newPackageName, element: childElement)
            }
        }
    }
}
