# StateModel

Sometimes you want to create a small data model, and the common approaches seem overly complicated.
In those cases `StateModel` may be for you.

The main idea is to flatten models into a very simple, generic structure, so that you can use a standard database without modifications.
Just define your models in code, and don't worry about tables, schemas, or any of the low-level details.
Then use your models like any other classes, while the model logic fetches all values directly from the database.
In addition to the simple usage, `StateModel` even provides a simple mechanism to synchronize/merge databases.

Here's how it works: A data model usually consists of different model classes, which are identified somehow (think PRIMARY KEY), and which have some properties assigned (which can point to other models).
The idea is to identify each property by a unique "path", which consists of:
- The id of the model class
- The id of the instance
- The id of the property

This tuple (ModelID, InstanceID, PropertyID) is termed a "path" and used to uniquely identify the value of a property, and everything is stored based on these identifiers.
This means that a database has essentially only two primary functions: `get()` and `set()`, which both operate on paths.
In practice, we need one additional function to provide all instances of a specific model type, so the actual database interface looks like this:
```swift
func get<Value>(_ path: KeyPath) -> Value? where Value: DatabaseValue
func set<Value>(_ value: Value, for path: KeyPath) where Value: DatabaseValue
func all<T>(model: ModelKey, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus) -> T?) -> [T]
```

This very compact interface makes it incredibly easy to write a database implementation, and there is no need to specify tables, schemas or anything else.
Interacting with the data model is done through lightweight wrappers, which define the model structure, and simply use the get/set functions of the database with the correct paths.

## Installation

Integrate this package like you would any other:

```swift
...
    dependencies: [
        .package(url: "https://github.com/christophhagen/StateModel", from: "3.0.0")
    ],
...
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "StateModel", package: "StateModel")
        ]
    ),
...
```

## Model definition

`StateModel` is inspired partially by `SwiftData` and `Fluent` when it comes to the specification of models, which is mostly done through property wrappers.
Here's a simple model to explain the concept:

 ```swift
 final class MyModel: Model<Int, Int, Int> {

     static let modelId = 1

     @Property(id: 42)
     var some: String = "Empty"
 }
 ```
 
You could already use this model without any additional work (apart from [choosing a database](#database-selection)).
Let's discuss the most important parts.

### Conforming to a model

Notice how `MyModel` inherits/conforms to `Model<Int, Int, Int>`. `Model` is actually a `typealias` that let's you inherit from a `BaseModel` and makes you conform to `ModelProtocol`.
The `BaseModel` provides the model with a reference to the database, and a unique id.
The conformance to `ModelProtocol` forces you to provide a `modelId` and is needed to interact with the database.
`BaseModel` is a generic type, and requires you to choose types for the model, instance, and property ids (in this case all `Int`).
More on that [later](#database-selection).

Note that you are free to provide the requirements for `ModelProtocol` yourself, but inheriting from `BaseModel` is usually the right choice.

### Model ID

A unique `modelId` needs to be specified for each model class, similar to how you would choose a table name for SQLite.
You can freely choose the data type (see [database selection](#database-selection)), but it makes sense to use some integer type.

### Properties

Each property of the model that is backed by the database must be annotated with a property wrapper like `@Property` (there are some [others](#references)).
This wrapper transforms the property, so that the current value is always retrieved from the database.
This is done by using the `database` property of the model (hidden in `BaseModel`) with the unique path of the property.
This path is contructed from the `modelId`, the instance `id` (from `BaseModel`), and the id set for `@Property` (`42` in this case).

The value type in this case is `String`, but any Swift type that conforms to `Codable` can be used.
It's also possible to provide a default value, which is used if the database does not contain a value for the property (the default value is not written to the database).

Properties already give a quite some options for your models, but a few additional features are needed.

### References

When you need to reference a single object of another model class, then `@Reference` is the way to go.

```swift
@Reference(id: 3)
var contained: NestedModel?
```

It creates a one-way reference to the object using the instance id.
The relationship is always optional, since there are no guarantees that a referenced model will be present,
and there would be no defined value when first creating a model.

Note that there is no mechanism to automatically handle inverse relationships, that's for you to manage.
There is also no possibility to specify cascading deletes.

### Reference Lists

Use `@ReferenceList` to handle one-to-many relationships.

```swift
@ReferenceList(id: 1)
var other: [NestedModel]
```
     
It works in a similar way as `@Reference`, and you can freely modify the list or its elements.
Internally, the list just manages an array of instance ids.
`@ReferenceList` can be used out of the box with `Array`, `Set` and `ContiguousArray`. You can also use it with additional sequence types if you conform it to `SequenceInitializable`.

## Database selection

In addition to the definition of the models, you need to make a few choices for the database, which depend on your use case.
Essentially, you need to choose a tuple (ModelId, InstanceId, PropertyId) of types that are used to construct the property paths.
Before writing the

### Database implementations

#### `InMemoryDatabase`
There is currently only one example implementation provided with `StateModel`, which keeps all data in memory.
You can directly use this database for initial testing, but production use will likely require persistence.

#### SQLite Datase

An implementation of a database with an underlying SQLite store is provided in [SQLiteStateDB](https://github.com/christophhagen/SQLiteStateDB).
It stores SQLite supported types (integers, doubles, strings) in separate tables, and encodes all other `Codable` values using a provided encoder.
The current implementation restricts the [key paths](#paths) to integers.

#### Custom implementation

You can also [write your own database](#database-implementation) by inheriting from `Database`.
This gives you all the freedom to store the data in an appropriate format, implement additional features, and apply performance optimizations.

### ID types

If you choose an existing implementation, then it may have already made decisions on certain implementation details, 
otherwise you have to decide the types of the ids to use.

The main choice concerns the structure of the paths that define each instance property.
A path consists of three components: Model ID, Instance ID, Property ID.
You can think of a path as `model.instance.property`, e.g. `customer.alice.age` (although IDs are recommended to be integers).
You must select appropriate data types to use for each component.

#### Model Key Type

This type defines the data type to use for the `modelId` which uniquely identifies each model class.
The recommended type is `UInt8`, which allows you to create 256 different model classes. 
Select a different model type to allow more, or if you have specific requirements for the ids.

#### Instance Key Type

This type is used for the unique ids of model instances, e.g. the `id` property of every object.
Its size determines the number of unique instances you can store in the database.
The recommendation is `UInt32`, which allows you to create 4,294,967,296 different instances for each model class.
Note that objects of different types are allowed to use the same id, since they will have different `modelId`s.

#### Property Key Type

This type is used to uniquely identify each property of a model class.
It's the value provided to `@Property`, `@Reference` and `@ReferenceList`.
It should be sufficient to use `UInt8`, unless you have specific requirements about the id structure.

#### Storage efficiency

The data types of the three path components is important because each property value will be stored using its own path.
This means that the appropriate selection of the data type can severely affect database performance.

### Specification

Once you have chosen good types, it's recommended to create a `typealias` to define the types to use with your models.

```swift
typealias MyModel = Model<UInt8, UInt32, UInt8>
```

In the case of the provided `InMemoryDatabase`, you could write:

```swift
typealias MyDatabase = InMemoryDatabase<UInt8, UInt32, UInt8>
```

This will simplify the model definition example from [earlier](#model-definition), so that you can write:

```
final class SomeModel: MyModel {
    static let modelId: UInt8 = 1
}
```

## Usage

The models defined using `StateModel` are largely used like any other class in Swift.

### Object creation

Any object you create is part of a database.
Use the database to create or get objects.

```swift
let model: MyModel = database.create(id: 123)

let other: MyModel? = database.get(id: 123)
```

You should not create models outside of the database.
Since each model requires a database reference, any modification will be written to the database, 
even if the actual instance is not registered with the database.
To modify objects without writing to the database, and commiting all changes at once, see [editing contexts](#editing-contexts).

### Property modification

Any of the `@Property` attributes on a model can be modified as you would normally do:

```swift
model.value = 2
let a = model.value + 3
model.value += a
other.value = 2 * model.value
```

### References

The same behaviour goes for references:

```swift
let other = database.create(id: 123, of: OtherModel.self)
model.inner = other
model.inner!.value = 32
```

### Model status

It's possible for instances to be deleted from the database:

```swift
let model: MyModel = ...
model.delete()
```

Deletion marks the object as deleted, which can be checked using the `status`:

```swift
model.delete()
print(model.status) // Prints "deleted"
```

For all other cases, the status will be `created`.

### References to deleted objects

When you delete a model, then any reference to it will be marked as deleted:

```swift
let nested: NestedModel
myObject.value = nested
nested.delete()
print(myObject.value!.status) // prints "deleted"
```

There is no reliable way to nullify these relationships without actively tracking them,
so they are just kept.
Actively set them to `nil` to remove a relationship.

When you delete a model that is referenced in a list, it will also be marked as deleted:

```swift
let main = MyModel
let some = OtherModel
main.innerList = [some]
some.delete()
print(main.innerList[0].status) // prints "deleted"
```

### Restoring objects

Since models are only marked deleted in the database, it's still possible to access their properties, and also to restore them:

```swift
let model: MyModel = ...
model.value = 12
model.delete()
print(model.status) // Prints "deleted"
model.insert()
print(model.value) // Prints "12"
```

Notice that the property values are still present after recreation of the model:

```swift
model.value = 12
model.delete()
let newModel: MyModel = database.create(id: model.id)
print(newModel.value) // Prints "12"
```

You should therefore be careful when reusing instance ids.

### Property Id Enum

It's very important that property ids are unique within a model.
It may be beneficial to create an `enum` to track all ids:

```swift
final class MyModel: MyDatabaseModel {
    static let modelId = 1
    
    enum PropertyId: UInt8 {
        case value = 1
        case otherValue = 2
    }
    
    @Property(id: PropertyId.value.rawValue)
    var value: String
    
    @Property(id: PropertyId.otherValue.rawValue)
    var otherValue: Double
}
```

This may remind you a bit of the `CodingKey` enums in `Codable` conformances,
except that it's currently not possible to automatically assign ids.
Note: It's also possible to directly use an enum as a `PropertyKey`, e.g. `Database<Int, Int, MyPropertyKeys`, but then all models in the database must use values from the enum for the property ids.

### History view

In many cases it will be sufficient to track the *current* state of the database.
But if you need to also access historic data, then you need to choose (or implement) a `HistoryDatabase`.
It provides all the features of a standard `Database`, but additionally allows you to view the database at a specific point in time:

```swift
let database = MyHistoryDatabase()
let yesterday = Date().addingTimeInterval(-86400)
let view = database.view(at: yesterday)
```

You can use the `HistoryView` in the same way as any other `Database`, and query model instances from it.
Note that making edits to a history view is not supported, and all modifications will be ignored.
There is no need to update existing model definitions, they can work with both `Database` and `HistoryDatabase`.

### Switching database implementations

You may sometimes want to use models in different database implementations.
This is possible as long as the key paths of the databases match.

So given a model specification:

```swift
typealias MyModel = Model<Int, Int, Int>
```

you may use the same model in an `InMemoryDatabase<Int, Int, Int>` as well as a `SQLiteDatabase`.
This makes it possible to use different databases e.g. for testing, or to later migrate to a new database without changing the model code.

### Editing contexts

In real applications you may want to first create new instances or change data, and then commit all of it to the database when ready.
This feature is made possible by contexts, which (similar to `ModelContext` in SwiftData) store all modifications until you save them.

```swift
let database = MyDatabase()
let context = database.createEditingContext()

let newItem: SomeModel = context.create(id: 123)
newItem.value = 42

context.commitChanges() // Saves the item to the database
```

For databases that also store a history (`HistoryDatabase`), 
you can also create a context that uses a snapshot of the database at the current date:

```swift
let database = MyHistoryDatabase()
let context = database.createEditingContextWithCurrentState()
```

Changes made to the database will then not appear in the context.

### Synchronization

It's possible to synchronize databases with each other quite easily when you supply your own database solution:
In the `set()` function of the database, copy the encoded value into a `Record`, which will provide a timestamp for the change.
Transmit the records to the database to be synchronized, and apply the updates again,
while checking for newer records.

The provided `InMemoryDatabase` offers a very basic form of synchronization for inspiration.

### Migration

There isn't much migrating to do for models in `StateModel`, since there are no fixed model schemas or other things that could produce conflicts.
Adding additional properties can be done without problems, since each new property will use the specified default if no value exists.
If the type of a property is changed, then the database will most likely not be able to decode the values anymore, which will cause the defaults to be applied.

## Database implementation

If you want to create your own database, here is a minimal example that just caches the data in memory:

```swift
final class MinimalDatabase<Key: PathKey>: Database<Key, Key, Key> {

    typealias KeyPath = Path<Key, Key, Key>

    private var cache: [KeyPath: Any] = [:]

    // MARK: Properties

    override func get<Value>(_ path: KeyPath) -> Value? where Value: Codable {
        cache[path] as? Value
    }

    override func set<Value>(_ value: Value, for path: KeyPath) where Value: Codable {
        cache[path] = value
    }

    // MARK: Instances

    override func all<T>(model: Key, where predicate: (_ instanceId: Key, _ value: InstanceStatus) -> T?) -> [T] {
        cache.compactMap { (path, value) -> T? in
            guard path.model == model,
                  path.property == PropertyKey.instanceId,
                  let value = value as? InstanceStatus else {
                return nil
            }
            return predicate(path.instance, value)
        }
    }
}
```

Isn't it great that this simple database can already handle all types of models?
Based on this template, you can easily implement caching, synchronization, persistance to disk, and many optimizations based on specific paths or properties.

If you want to track the history of each property, so that you can revert changes or benefit from additional features (like `HistoryView`), then implement a `HistoryDatabase` instead.

> Tip: First conform to `DatabaseProtocol` or `HistoryDatabaseProtocol` to determine all the required functions to implement, then inherit from `Database` and `HistoryDatabase` to complete the implementation.
> If you inherit from the base classes without overriding the required methods (`get()`, `set()` and `all()`) then a `fatalError` will be produced at runtime.

## Roadmap

Due to the cleverly simple concept, future features will be fairly easy to add.
The following things are currently planned:

- [x] Database implementations
- [x] Support different databases for models (e.g. for testing and production)
- [x] Editing contexts with undo and save
- [x] Viewing objects at a point in time
- [x] Explore macros to automatically generate property ids (didn't work) 
- [ ] Update notifications similar to `ObservableObject` for use with SwiftUI
- [ ] Non-optional references with a default value
