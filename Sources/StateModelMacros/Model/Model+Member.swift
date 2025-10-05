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
        let id = try extractModelId(from: classDeclaration.attributes)
        let properties = extractProperties(from: classDeclaration)
        return [
            modelId(id: id),
            databaseReference,
            instanceId,
            initializer,
            objectWillChange,
            createFunction(with: properties)
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

    private static func extractProperties(from classDecl: ClassDeclSyntax) -> [(name: String, type: String)] {
        // Collect stored properties
        var props: [(name: String, type: String)] = []

        for member in classDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    guard
                        let id = binding.pattern.as(IdentifierPatternSyntax.self),
                        let type = binding.typeAnnotation?.type
                    else { continue }
                    let idText = id.identifier.text.trimmingCharacters(in: .whitespaces)
                    let typeText = type.description.trimmingCharacters(in: .whitespaces)
                    props.append((idText, typeText))
                }
            }
        }
        return props
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

    private static func createFunction(with properties: [(name: String, type: String)]) -> DeclSyntax {
        let params = properties.map { "\($0.name): \($0.type)" }
        let args = properties.map { "instance.\($0.name) = \($0.name)" }
        let allParams = ["in database: Database", "id: InstanceKey"] + params
        return """
        /**
         Create a new instance of the model.
         - Parameter database: The database in which the instance is created.
         - Parameter id: The unique id of the instance
        */
        static func create(\(raw: allParams.joined(separator: ", "))) -> Self {
            let instance: Self = database.create(id: id)
            \(raw: args.joined(separator: "\n    "))
            return instance
        }
        """
    }
}
