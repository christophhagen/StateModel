import SwiftSyntax

struct ParameterDefinition {
    let name: String
    let type: String
    let defaultValue: String?
}

struct CommandDefinition {

    let name: String

    let id: Int

    let parameters: [ParameterDefinition]
}

func isCommand() throws -> Bool {
    false
}

func determineCommandAndArgumentIds(func funcDecl: FunctionDeclSyntax, node: AttributeSyntax) throws -> CommandDefinition {
    guard let macroArguments = node.arguments?.as(LabeledExprListSyntax.self)?.map({ $0 }) else {
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

    let parameters = try extractFunctionParameters(funcDecl)

    let commandName = funcDecl.name.text

    return .init(
        name: commandName,
        id: commandId,
        parameters: parameters)
}

func extractFunctionParameters(_ funcDecl: FunctionDeclSyntax) throws -> [ParameterDefinition] {
    try funcDecl.signature.parameterClause.parameters.map { param in
        let name = param.firstName.text
        guard let paramType = param.type.as(IdentifierTypeSyntax.self) else {
            throw StateModelError("Failed to determine type of parameter '\(name)'")
        }
        let type = paramType.name.text

        return ParameterDefinition(
            name: name,
            type: type,
            defaultValue: nil)
    }
}
