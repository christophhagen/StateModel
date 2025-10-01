import SwiftSyntax
import SwiftSyntaxMacros

protocol ModelMacroProtocol: MemberMacro {

    static var macroName: String { get }
}

extension ModelMacroProtocol {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
            throw StateModelError("Expected a class declaration for @\(macroName)")
        }
        let id = try extractModelId(from: classDeclaration.attributes)
        return [
            modelId(id: id),
            databaseReference,
            instanceId,
            initializer
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
        throw StateModelError("@\(macroName) requires an 'id' parameter with the model id (Int)")
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
        public required init(database: Database, id: InstanceKey) {
            self.database = database
            self.id = id
        }
        """
    }
}
