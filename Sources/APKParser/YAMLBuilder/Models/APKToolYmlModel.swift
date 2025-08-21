import Foundation

public struct APKToolYmlModel: Codable {
    public var packageInfo: PackageInfo
    public var versionInfo: VersionInfo
}

public struct PackageInfo: Codable {
    public var renameManifestPackage: String?
}

public struct VersionInfo: Codable {
    public var versionCode: String
    public var versionName: String
}
