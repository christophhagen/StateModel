import Combine

/**
 Use the `Model` macro to define models to store in a database.

 Attach the macro to your model definition to make it work with databases:

 ```swift
 @Model(id: 1)
 final class MyModel {

     @Property(id: 42)
     var some: String
 }
 ```

 The `id` parameter for `@Model` represents the unique identifier for `MyModel`, while the `id` parameter for `@Property` uniquely identifies the property `some`.
 When creating a type of `MyModel`, a unique id for the instance needs to be supplied as well:

 ```swift
 let database = MyDatabase(...)
 let instance: MyModel = database.create(id: 123)
 ```

 When now setting the property `some`, the database will be informed about the change:

 ```swift
 instance.some = "abc"
 ```

 The update has the form:

 ```
 (model: 1, instance: 123, property: 42, value: "abc")
 ```

 This record will be persisted by the database. When a property is accessed, then a request to the database is made:

 ```
 (model: 1, instance: 123, property: 42)
 ```

 The database will retrieve the current value ( `"abc"`) for the key path, and hand it to the instance:

 ```swift
 print(instance.some) // prints "abc"
 ```
 */
@attached(extension, conformances: ModelProtocol, ObservableObject)
@attached(member, names: named(id), named(modelId), named(database), named(init(database:id:)), named(objectWillChange), named(PropertyId), named(create), named(deleteAndClearProperties))
public macro Model(id: ModelKey) = #externalMacro(
    module: "StateModelMacros",
    type: "ModelMacro")
