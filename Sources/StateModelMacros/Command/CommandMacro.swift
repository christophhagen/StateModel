import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftCompilerPlugin
import SwiftDiagnostics

public struct CommandMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf decl: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Only works on functions
        guard let funcDecl = decl.as(FunctionDeclSyntax.self) else {
            return []
        }

        let accessModifier = determineAccessModifier(funcDecl.modifiers).map { $0 + " " } ?? ""

        let command = try determineCommandAndArgumentIds(func: funcDecl, node: node)

        // This macro is a no-op (it generates no peers)
        return [
            generateCommandFunction(command, access: accessModifier),
            generateExecutionFunction(command)
        ]
    }

    private static func generateCommandFunction(_ command: CommandDefinition, access: String) -> DeclSyntax {
        let parameterList = command.parameters.map { "\($0.name): \($0.type)" }.joined(separator: ", ")

        var functionLines: [String] = []
        if command.parameters.isEmpty {
            functionLines.append("CommandBuilder(path: path(of: CommandId.\(command.name)))")
        } else {
            functionLines.append("let builder = CommandBuilder(path: path(of: CommandId.\(command.name)))")
            for (id, parameter) in command.parameters.enumerated() {
                functionLines.append("builder.add(\(parameter.name), for: \(id + 1))")
            }
            functionLines.append("return builder")
        }
        let functionContent = functionLines.joined(separator: "\n    ")
        return """
            \(raw: access)func \(raw: command.name)Command(\(raw: parameterList)) -> CommandBuilder {
                \(raw: functionContent)
            }
            """
    }

    private static func generateExecutionFunction(_ command: CommandDefinition) -> DeclSyntax {
        var functionLines: [String] = []
        if !command.parameters.isEmpty {
            for (id, parameter) in command.parameters.enumerated() {
                functionLines.append("let \(parameter.name): \(parameter.type) = try command.argument(for: \(id + 1))")
            }
        }

        let parameterList = command.parameters.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
        functionLines.append("self.\(command.name)(\(parameterList))")
        let functionContent = functionLines.joined(separator: "\n    ")
        return """
        private func \(raw: command.name)(command: CommandExecutor) throws(StateError) {
            \(raw: functionContent)
        }
        """
    }
}
