import SwiftSyntax
import SwiftSyntaxMacros
import Foundation

extension ModelMacro: ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        [
            try ExtensionDeclSyntax("extension \(type): ModelProtocol") { },
            try ExtensionDeclSyntax("extension \(type): ObservableObject") { }
        ]
    }
}
