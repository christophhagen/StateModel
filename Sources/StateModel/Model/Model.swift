
/**
 A model represents the basic type to inherit from when defining models to store in the database.

 Assuming a type `MyDatabase` implements ``Database`` with a ``PathKey`` of type ``Int``,
 then a model for that database can be defined as:

 ```swift
 final class MyModel: Model<MyDatabase> {

     static let modelId = 1

     @Property(id: 42)
     var some: String
 }
 ```

 Here the `modelId` represents the unique identifier for `MyModel`, while `id` uniquely identifies the property `some`.
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
public typealias Model<S: DatabaseProtocol> = BaseModel<S> & ModelProtocol
