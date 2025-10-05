import SwiftSyntax
import SwiftSyntaxMacros

struct PropertySpecification {
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
            "if \(name) != \(usableDefaultValue) {",
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

extension ModelMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
            throw StateModelError("Expected a class declaration for @Model")
        }
        let id = try extractModelId(from: classDeclaration.attributes)
        let properties = try extractProperties(from: classDeclaration)
        try ensureUniqueIds(properties: properties)
        return [
            modelId(id: id),
            databaseReference,
            instanceId,
            initializer,
            objectWillChange,
            createFunction(with: properties),
            createPropertyEnum(with: properties),
            createDeleteFunction(with: properties)
        ]
    }

    private static func extractModelId(from attributes: AttributeListSyntax) throws -> ExprSyntax {
        for attribute in attributes {
            guard case .attribute(let a) = attribute else {
                continue
            }
            guard let arguments = a.arguments?.as(LabeledExprListSyntax.self) else {
                continue
            }
            for argument in arguments {
                guard argument.label?.tokenKind == .identifier("id") else {
                    continue
                }
                return argument.expression
            }
        }
        throw StateModelError("@Model requires an 'id' parameter with the model id (Int)")
    }

    private static func extractProperties(from classDecl: ClassDeclSyntax) throws -> [PropertySpecification] {
        return try classDecl.memberBlock.members.compactMap { member in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                return nil
            }
            guard let property = try extractProperty(varDecl) else {
                return nil
            }
            return property
        }
    }

    private static func extractProperty(_ varDecl: VariableDeclSyntax) throws -> PropertySpecification? {
        guard let rawId = try findId(variable: varDecl) else {
            return nil
        }
        for binding in varDecl.bindings {
            guard let nameDecl = binding.pattern.as(IdentifierPatternSyntax.self) else {
                throw StateModelError("Could not determine name of a stored property")
            }
            let name = nameDecl.identifier.text.trimmingCharacters(in: .whitespaces)

            guard let typeDecl = binding.typeAnnotation else {
                throw StateModelError("Could not determine type of property \(name)")
            }
            let type = typeDecl.type.description.trimmingCharacters(in: .whitespaces)
            let defaultValue = binding.initializer?.value.description.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let id = Int(rawId) else {
                throw StateModelError("`id` of property \(name) is not an integer")
            }
            return .init(id: id, name: name, type: type, defaultValue: defaultValue)
        }
        throw StateModelError("Could not determine name and type of stored property with id '\(rawId)'")
    }

    private static func findId(variable: VariableDeclSyntax) throws -> String? {
        let attributes = variable.attributes

        for attribute in attributes {
            guard let attr = attribute.as(AttributeSyntax.self) else {
                continue
            }

            // Check the attribute name
            guard let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
                continue
            }
            guard name == "Property" || name == "Reference" || name == "ReferenceList" else {
                continue
            }
            guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
                throw StateModelError("Failed to get arguments of @\(name) attribute")
            }
            for arg in arguments {
                guard arg.label?.text == "id" else {
                    continue
                }
                return arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private static func ensureUniqueIds(properties: [PropertySpecification]) throws {
        var usedIds: Set<Int> = []
        for property in properties {
            let id = property.id
            if usedIds.contains(id) {
                let nameList = properties.filter { $0.id == id }.map { $0.name }.joined(separator: ", ")
                throw StateModelError("Property id \(id) is not unique, used by: \(nameList)")
            }
            usedIds.insert(id)
        }
    }

    private static func modelId(id: ExprSyntax) -> DeclSyntax {
        """
        static let modelId: Int = \(id)
        """
    }

    private static var databaseReference: DeclSyntax {
        """
        /// The reference to the database to which this object is linked
        public unowned let database: Database
        """
    }

    private static var instanceId: DeclSyntax {
        """
        /// The unique id of the instance
        public let id: InstanceKey
        """
    }

    private static var initializer: DeclSyntax {
        """
        /**
         Create a model.
         - Parameter database: The reference to the model database to read and write property values
         - Parameter id: The unique id of the instance
         - Note: This initializer should never be used directly. Create object through the database functions
        */
        @available(*, deprecated, message: "Models should be created by using `Database.create(id:)`")
        public required init(database: Database, id: InstanceKey) {
            self.database = database
            self.id = id
        }
        """
    }

    private static var objectWillChange: DeclSyntax {
        "public let objectWillChange = ObservableObjectPublisher()"
    }

    private static func createFunction(with properties: [PropertySpecification]) -> DeclSyntax {
        let params = properties.map { $0.functionParameterString }
        let args: String = properties.map { $0.linesForSetter(instanceName: "instance") }
            .joined()
            .joined(separator: "\n    ")
        let allParams = ["in database: Database", "id: InstanceKey"] + params
        return """
        /**
         Create a new instance of the model.
         - Parameter database: The database in which the instance is created.
         - Parameter id: The unique id of the instance
        */
        static func create(\(raw: allParams.joined(separator: ", "))) -> Self {
            let instance: Self = database.create(id: id)
            \(raw: args)
            return instance
        }
        """
    }

    private static func createPropertyEnum(with properties: [PropertySpecification]) -> DeclSyntax {
        let cases = properties.map { "    case \($0.name) = \($0.id)" }
        return """
        enum PropertyId: PropertyKey, CaseIterable {
        \(raw: cases.joined(separator: "\n"))
        }
        """
    }

    private static func createDeleteFunction(with properties: [PropertySpecification]) -> DeclSyntax {
        let setters = properties.map { $0.deletionSetter }.joined(separator: "    \n")
        return """
        /**
         Delete the instance and reset overwrite all properties with default values
        */
        func deleteAndClearProperties() {
            \(raw: setters)
            self.delete()
        }
        """
    }
}
