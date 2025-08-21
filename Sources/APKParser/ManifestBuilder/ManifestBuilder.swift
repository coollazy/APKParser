import Foundation

public class ManifestBuilder: XMLBuilder {
    var applications: [XMLElement] {
        xml.rootElement()?.elements(forName: "application") ?? []
    }
    
    var firstApplicationMetaData: [XMLElement] {
        applications.first?.elements(forName: "meta-data") ?? []
    }
    
    var firstApplicationCocosLaunchActivity: XMLElement? {
        applications.first?.elements(forName: "activity").first {
            $0.attribute(forName: "android:name")?.stringValue == "com.cocos.game.ui.launch.LaunchActivity"
        }
    }
    
    // MARK: Replace the android:value by android:name
    func replaceApplicationMetaData(name: String?, value: String?) -> Self {
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
