import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


extension ObservableModelMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        [
            databaseReference,
            instanceId,
            initializer
        ]
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
