import SwiftSyntax
import SwiftSyntaxMacros

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
        let accessModifier = determineAccessModifier(classDeclaration)
        let id = try extractModelId(from: classDeclaration.attributes)
        let properties = try extractProperties(from: classDeclaration)
        let commands = try extractCommands(from: classDeclaration)
        try ensureUniqueIds(properties: properties)
        var members: [DeclSyntax] = []
        members.append(modelId(id: id, access: accessModifier))
        members.append(databaseReference(access: accessModifier))
        members.append(instanceId(access: accessModifier))
        members.append(initializer(access: accessModifier))
        members.append(objectWillChange(access: accessModifier))
        members.append(createFunction(with: properties, access: accessModifier))
        if !properties.isEmpty {
            members.append(createPropertyEnum(with: properties, access: accessModifier))
        }
        members.append(createDeleteFunction(with: properties, access: accessModifier))
        members.append(createUpdatesFunction(with: properties, access: accessModifier))
        members.append(applyUpdatesFunction(with: properties, access: accessModifier))
        if !commands.isEmpty {
            members.append(commandIdEnum(with: commands, access: accessModifier))
            members.append(createCommandExecutionFunction(with: commands, access: accessModifier))
        }
        return members
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
        guard let (property, rawId) = try findId(variable: varDecl) else {
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
            let type = exprWithoutTrailingComments(typeDecl.type)
            let defaultValue = extractDefaultValue(binding.initializer)

            guard let id = ModelKey(rawId) else {
                throw StateModelError("`id` of property \(name) is not an integer")
            }
            return .init(property: property, id: id, name: name, type: type, defaultValue: defaultValue)
        }
        throw StateModelError("Could not determine name and type of stored property with id '\(rawId)'")
    }

    private static func extractDefaultValue(_ initializer: InitializerClauseSyntax?) -> String? {
        guard let initializer else {
            return nil
        }
        let expr = initializer.value
        return exprWithoutTrailingComments(expr)
    }

    private static func findId(variable: VariableDeclSyntax) throws -> (type: WrapperType, id: String)? {
        let attributes = variable.attributes

        for attribute in attributes {
            guard let attr = attribute.as(AttributeSyntax.self) else {
                continue
            }

            // Check the attribute name
            guard let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
                continue
            }
            guard let type = WrapperType(rawValue: name) else {
                continue
            }
            guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
                throw StateModelError("Failed to get arguments of @\(name) attribute")
            }
            for arg in arguments {
                guard arg.label?.text == "id" else {
                    continue
                }
                let id = arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                return (type, id)
            }
        }
        return nil
    }

    private static func ensureUniqueIds(properties: [PropertySpecification]) throws {
        var usedIds: Set<ModelKey> = []
        for property in properties {
            let id = property.id
            if usedIds.contains(id) {
                let nameList = properties.filter { $0.id == id }.map { $0.name }.joined(separator: ", ")
                throw StateModelError("Property id \(id) is not unique, used by: \(nameList)")
            }
            usedIds.insert(id)
        }
    }

    private static func extractCommands(from classDecl: ClassDeclSyntax) throws -> [CommandDefinition] {
        return try classDecl.memberBlock.members.compactMap { member -> CommandDefinition? in
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                return nil
            }
            guard let id = try getCommandId(funcDecl) else {
                return nil
            }

            let commandName = funcDecl.name.text

            let parameters = try extractFunctionParameters(funcDecl)

            return CommandDefinition(
                name: commandName,
                id: id,
                parameters: parameters)
        }
    }

    private static func getCommandId(_ funcDecl: FunctionDeclSyntax) throws -> Int? {
        let attributes = funcDecl.attributes.compactMap { $0.as(AttributeSyntax.self) }
        for attribute in attributes {
            guard let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self) else {
                continue
            }
            guard attributeName.name.text == "Command" else {
                continue
            }
            guard attributes.count == 1 else {
                throw StateModelError("Multiple attributes not supported for functions annotated with @Command")
            }
            guard let macroArguments = attribute.arguments?.as(LabeledExprListSyntax.self)?.map({ $0 }) else {
                throw StateModelError("Could not determine macro arguments")
            }
            guard macroArguments.count == 1 else {
                throw StateModelError("Expected exactly two macro arguments")
            }
            guard let idLiteral = macroArguments[0].expression.as(IntegerLiteralExprSyntax.self) else {
                throw StateModelError("Command id must be an integer literal")
            }
            guard let commandId = Int(idLiteral.literal.text) else {
                throw StateModelError("Command id must be a valid integer literal")
            }
            return commandId
        }
        return nil
    }

    // MARK: Generated members

    private static func modelId(id: ExprSyntax, access: String) -> DeclSyntax {
        """
        /**
         The unique id of this model in the database.
         */
        \(raw: access)static let modelId: ModelKey = \(id)
        """
    }

    private static func databaseReference(access: String) -> DeclSyntax {
        """
        /// The reference to the database to which this object is linked
        \(raw: access)unowned let database: Database
        """
    }

    private static func instanceId(access: String) -> DeclSyntax {
        """
        /// The unique id of the instance
        \(raw: access)let id: InstanceKey
        """
    }

    private static func initializer(access: String) -> DeclSyntax {
        """
        /**
         Create a model.
         - Parameter database: The reference to the model database to read and write property values
         - Parameter id: The unique id of the instance
         - Note: This initializer should never be used directly. Create object through the database functions
         */
        @available(*, deprecated, message: "Models should be created by using `Database.create(id:)`")
        \(raw: access)required init(database: Database, id: InstanceKey) {
            self.database = database
            self.id = id
        }
        """
    }

    private static func objectWillChange(access: String) -> DeclSyntax {
        """
        /**
         The publisher to notify the object that the underlying data has changed.
         */
        \(raw: access)let objectWillChange = ObservableObjectPublisher()
        """
    }

    private static func createFunction(with properties: [PropertySpecification], access: String) -> DeclSyntax {
        let params = properties.map { $0.functionParameterString }
        let allParams = ["in database: Database", "id: InstanceKey"] + params

        var functionLines: [String] = []
        if !properties.isEmpty {
            functionLines += [
                "func areNotEqual<T>(_ a: T, _ b: T) -> Bool { false }",
                "func areNotEqual<T: Equatable>(_ a: T, _ b: T) -> Bool { a != b }",
                "let instance: Self = database.create(id: id)"
            ]
            for property in properties {
                functionLines.append(contentsOf: property.linesForSetter(instanceName: "instance"))
            }
            functionLines.append("return instance")
        } else {
            functionLines.append("database.create(id: id)")
        }

        return """
        /**
         Create a new instance of the model.
         - Parameter database: The database in which the instance is created.
         - Parameter id: The unique id of the instance
         */
        \(raw: access)static func create(\(raw: allParams.joined(separator: ", "))) -> Self {
            \(raw: functionLines.joined(separator: "\n    "))
        }
        """
    }

    private static func createPropertyEnum(with properties: [PropertySpecification], access: String) -> DeclSyntax {
        let cases = properties.map { "    case \($0.name) = \($0.id)" }.joined(separator: "\n")
        return """
        /**
         All properties tracked by the model.
         */
        \(raw: access)enum PropertyId: PropertyKey, CaseIterable {
        \(raw: cases)
        }
        """
    }

    private static func createDeleteFunction(with properties: [PropertySpecification], access: String) -> DeclSyntax {
        var functionLines: [String] = []
        for property in properties {
            functionLines.append(property.deletionSetter)
        }
        functionLines.append("self.delete()")
        let functionContent = functionLines.joined(separator: "\n    ")
        return """
            /**
             Delete the instance and set all properties with default values
             */
            \(raw: access)func deleteAndClearProperties() {
                \(raw: functionContent)
            }
            """
    }

    private static func createUpdatesFunction(with properties: [PropertySpecification], access: String) -> DeclSyntax {
        var functionLines: [String] = []
        for property in properties {
            functionLines.append("_ = \(property.name)")
        }
        functionLines.append("_ = status")
        let functionContent = functionLines.joined(separator: "\n    ")

        return """
            \(raw: access)func accessAllPropertiesForUpdateCalculation() {
                \(raw: functionContent)
            }
            """
    }

    private static func applyUpdatesFunction(with properties: [PropertySpecification], access: String) -> DeclSyntax {
        var functionLines: [String] = []
        for property in properties {
            functionLines.append("try update.update(PropertyId.\(property.name), of: \(property.type).self)")
        }
        functionLines.append("try update.updateStatus()")
        let functionContent = functionLines.joined(separator: "\n    ")
        return """
            \(raw: access)func apply(update: InstanceUpdateExecutor) throws(StateError) {
                \(raw: functionContent)
            }
            """
    }

    private static func commandIdEnum(with commands: [CommandDefinition], access: String) -> DeclSyntax {
        let cases = commands.map { "    case \($0.name) = \($0.id)" }.joined(separator: "\n")
        return """
            \(raw: access)enum CommandId: PropertyKey {
            \(raw: cases)
            }
            """
    }

    private static func createCommandExecutionFunction(with commands: [CommandDefinition], access: String) -> DeclSyntax {
        let cases = commands.map { "case .\($0.name): try \($0.name)(command: command)" }.joined(separator: "\n")
        return """
            \(raw: access)func execute(command: CommandExecutor) throws(StateError) {
                let commandId: CommandId = try command.commandId()

                switch commandId {
                \(raw: cases)
                }
            }
            """
    }
}

func exprWithoutTrailingComments(_ expr: ExprSyntax) -> String {
    let filteredTrivia = expr.trailingTrivia.filter {
        switch $0 {
        case .lineComment, .blockComment: false
        default: true
        }
    }

    let cleanedToken = expr.with(\.trailingTrivia, Trivia(pieces: filteredTrivia))
    return cleanedToken.description.trimmingCharacters(in: .whitespacesAndNewlines)
}

func exprWithoutTrailingComments(_ expr: TypeSyntax) -> String {
    // Filter out comment trivia
    let filteredTrivia = expr.trailingTrivia.filter {
        switch $0 {
        case .lineComment, .blockComment: false
        default: true
        }
    }
    let cleanedToken = expr.with(\.trailingTrivia, Trivia(pieces: filteredTrivia))
    return cleanedToken.description.trimmingCharacters(in: .whitespacesAndNewlines)
}

func determineAccessModifier(_ classDecl: ClassDeclSyntax) -> String {
    guard let modifier = determineAccessModifier(classDecl.modifiers) else {
        return ""
    }
    if modifier == "private" {
        return "fileprivate "
    }
    return modifier + " "
}

func determineAccessModifier(_ modifiers:  DeclModifierListSyntax ) -> String? {
    // Extract access modifier (if any)
    let accessModifier = modifiers.first(where: { modifier in
        switch modifier.name.tokenKind {
        case .keyword(.public), .keyword(.internal), .keyword(.private), .keyword(.fileprivate), .keyword(.open):
            return true
        default:
            return false
        }
    })

    return accessModifier?.name.text
}
