
@attached(extension, conformances: ModelProtocol)
@attached(member, names: named(id), named(database), named(init(database:id:)), named(PropertyId), named(get), named(getOrDefault), named(set), named(_InstanceKey), named(_PropertyKey))
public macro Model() = #externalMacro(
    module: "StateModelMacros",
    type: "ModelMacro")
