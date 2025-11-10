
@attached(peer, names: arbitrary)
public macro Command(id: Int) = #externalMacro(
    module: "StateModelMacros",
    type: "CommandMacro"
)
