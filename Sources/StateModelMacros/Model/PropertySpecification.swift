
struct PropertySpecification {
    let property: WrapperType
    let id: Int
    let name: String
    let type: String
    let defaultValue: String?

    var functionParameterString: String {
        "\(name): \(typeForParameter)\(defaultValueInitializer)"
    }

    func linesForSetter(instanceName: String) -> [String] {
        guard let usableDefaultValue else {
            // If there is no default value to compare to
            // just set the value
            return ["\(instanceName).\(name) = \(name)"]
        }
        if usableDefaultValue == "nil" {
            return [
                "if let \(name) {",
                "    \(instanceName).\(name) = \(name)",
                "}"
            ]
        }
        return [
            "if areNotEqual(\(name), \(usableDefaultValue)) {",
            "    \(instanceName).\(name) = \(name)",
            "}"
        ]
    }

    var deletionSetter: String {
        // Here we assume that any property that doesn't have a default value
        // is an (implicitly unwrapped) optional, so we set it to nil
        "\(name) = \(usableDefaultValue ?? "nil")"
    }

    private var typeForParameter: String {
        guard type.hasSuffix("!") else {
            return type
        }
        return String(type.dropLast("!".count))
    }

    private var usableDefaultValue: String? {
        if property == .listReference {
            return ".init()"
        }
        if let defaultValue {
            return defaultValue
        }
        if type.hasSuffix("?") {
            return "nil"
        }
        if type.hasSuffix("!") {
            return nil
        }
        return "\(type).`default`"
    }

    private var defaultValueInitializer: String {
        if let usableDefaultValue {
            return " = \(usableDefaultValue)"
        }
        return ""
    }
}
