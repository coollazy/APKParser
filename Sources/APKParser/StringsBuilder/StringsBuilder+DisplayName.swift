public extension StringsBuilder {
    // MARK: - Google App Key
    func replace(displayName: String?) -> Self {
        replace(name: "app_name", value: displayName)
    }
}
