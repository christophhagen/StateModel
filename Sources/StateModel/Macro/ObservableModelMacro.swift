import Combine

/**
 A macro for models that conform to ``ObservableObject``.

 Instead of adopting the ``@Model`` macro for model definitions, use ``@ObservableModel``:

 ```swift
 @ObservableModel(id: 1)
 final class MyModel {

 }
 ```

 It's then possible to use your model types in SwiftUI views, as they conform to ``ObservableObject``.
 Whenever a property is changed in the database, the existing object is notified about the change, redrawing SwiftUI views.

 - Note: Observing only works when wrapping a database with ``ObservableDatabase``,
 and accessing all model instances though this wrapper.
 */
@attached(extension, conformances: ModelProtocol, ObservableObject)
@attached(member, names: named(id), named(modelId), named(database), named(init(database:id:)), named(PropertyId), named(get), named(getOrDefault), named(set), named(_InstanceKey), named(_PropertyKey))
public macro ObservableModel(id: Int) = #externalMacro(
    module: "StateModelMacros",
    type: "ObservableModelMacro")
