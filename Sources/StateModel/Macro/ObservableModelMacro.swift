import Combine

@attached(extension, conformances: ModelProtocol, ObservableObject)
@attached(member, names: named(id), named(modelId), named(database), named(init(database:id:)), named(PropertyId), named(get), named(getOrDefault), named(set), named(_InstanceKey), named(_PropertyKey))
public macro ObservableModel(id: Int) = #externalMacro(
    module: "StateModelMacros",
    type: "ObservableModelMacro")
