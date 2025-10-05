import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StateModelPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModelMacro.self
    ]
}
