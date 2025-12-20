import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

public class ManifestBuilder: XMLBuilder {
    public var applications: [XMLElement] {
        xml.rootElement()?.elements(forName: "application") ?? []
    }
    
    public var firstApplicationMetaData: [XMLElement] {
        applications.first?.elements(forName: "meta-data") ?? []
    }
    
    public var firstApplicationCocosLaunchActivity: XMLElement? {
        applications.first?.elements(forName: "activity").first {
            $0.attribute(forName: "android:name")?.stringValue == "com.cocos.game.ui.launch.LaunchActivity"
        }
    }
    
    // MARK: Replace the android:value by android:name
    public func replaceApplicationMetaData(name: String?, value: String?) -> Self {
        guard let name = name else {
            return self
        }
        let meta = firstApplicationMetaData.first {
            $0.attribute(forName: "android:name")?.stringValue == name
        }
        guard let meta = meta else {
            return self
        }
        meta.attribute(forName: "android:value")?.stringValue = value
        return self
    }
    
    /// Replaces an existing scheme value within `<data>` tags inside `<intent-filter>` elements.
    ///
    /// This method searches all `<activity>` tags, then all their `<intent-filter>` children,
    /// and finally all `<data>` children within those filters. If a `<data>` tag has an
    /// `android:scheme` attribute matching `oldScheme`, its value is updated to `newScheme`.
    ///
    /// - Parameters:
    ///   - oldScheme: The scheme string to search for (e.g., "${LINK_DEEP_APP_KEY}").
    ///   - newScheme: The new scheme string to replace with.
    /// - Returns: The `ManifestBuilder` instance for method chaining.
    @discardableResult
    public func replaceScheme(oldScheme: String, newScheme: String) -> Self {
        do {
            // Find all <data> tags with an android:scheme attribute using XPath
            // This is more robust than manually traversing the tree
            let dataNodes = try xml.nodes(forXPath: "//activity/intent-filter/data")
            
            var replacedCount = 0
            for node in dataNodes {
                // On Linux (FoundationXML), 'XMLNode' might not directly cast to 'XMLElement' easily if it's treated as a generic node,
                // but usually for elements it works. Let's use XMLNode methods if possible or cast.
                // In FoundationXML, XMLElement inherits from XMLNode.
                if let element = node as? XMLElement,
                   let schemeAttribute = element.attribute(forName: "android:scheme"),
                   schemeAttribute.stringValue == oldScheme {
                    
                    schemeAttribute.stringValue = newScheme
                    replacedCount += 1
                }
            }
            
            if replacedCount == 0 {
                debugPrint("ManifestBuilder: No scheme matching '\(oldScheme)' was found for replacement.")
            }
        } catch {
            debugPrint("ManifestBuilder: Error replacing scheme - \(error.localizedDescription)")
        }
        
        return self
    }
}

extension ManifestBuilder {
    public var iconName: String? {
        guard let name = applications.first?.attribute(forName: "android:icon")?.stringValue?.components(separatedBy: "/").last else {
            return nil
        }
        return name + ".png"
    }
    public var iconRoundName: String? {
        guard let name = applications.first?.attribute(forName: "android:roundIcon")?.stringValue?.components(separatedBy: "/").last else {
            return nil
        }
        return name + ".png"
    }
}
