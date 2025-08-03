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

This tuple (ModelID, InstanceID, PropertyID) is used to uniquely identify the value of a property, and everything is stored based on these identifiers.
This means that a database has essentially only two primary functions: 

```
func get(_ path: Path) -> Value?
func set(_ value: Value, for path: Path)
```

This makes it incredibly easy to write a database implementation, and there is no need to specify tables, schemas or anything else.
Interacting with the data model is done through lightweight wrappers, which define the model structure, and simply use the get/set functions of the database with the correct paths.

## Installation

Integrate this package like you would any other:

```swift
...
    dependencies: [
        .package(url: "https://github.com/christophhagen/StateModel", from: "1.0.0")
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
 final class MyModel: Model<MyDatabase> {

     static let modelId = 1

     @Property(id: 42)
     var some: String = "Empty"
 }
 ```
 
You could already use this model without any additional work (apart from [defining the database](#database-definition)).
Let's discuss the most important parts.

### Conforming to a model

Notice how `MyModel` inherits/conforms to `Model<MyDatabase>`. `Model` is actually a `typealias` that let's you inherit from a `BaseModel` and makes you conform to `ModelProtocol`.
The `BaseModel` provides the model with a reference to the database, and a unique id.
The conformance to `ModelProtocol` forces you to provide a `modelId` and is needed to interact with the database.
`BaseModel` is a generic type, and requires you to choose a database implementation, which in this case is `MyDatabase`.
More on that [later](#database-definition).

Note that you are free to provide the requirements for `ModelProtocol` yourself, but inheriting from `BaseModel` is a good start.

### Model ID

A unique `modelId` needs to be specified for each model class, similar to how you would choose a table name for SQLite.
You can freely choose the data type (see [database definition](#database-definition)), but generally it will be an integer.

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
var other: List<NestedModel>
```
     
It works in a similar way as `@Reference`, but provides you with a `List` of objects, which you can modify at will.
Internally, the list just manages an array of instance ids, and the model object is only loaded when accessing an element.

## Database definition

In addition to the definition of the models, you need to make a few choices for the database, which depend on your use case.
First you have to select an implementation that conforms to `Database`.
There is currently only one example implementation provided, which keeps all data in memory.
You can also [write your own database](#database-implementation) by conforming to `Database`.
If you choose an existing implementation, then it may have already made decisions on certain implementation details, 
otherwise you have to decide a few details.

The main choice concerns the structure of the paths that define each instance property.
A path consists of three components: Model ID, Instance ID, Property ID.
You can think of a path as `model.instance.property`, e.g. `customer.alice.age` (although IDs are recommended to be integers).
You must select appropriate data types to use for each component.

### Model Key Type

This type defines the data type to use for the `modelId` which uniquely identifies each model class.
The recommended type is `UInt8`, which allows you to create 256 different model classes. Select a different model type to allow more, or if you have specific requirements for the ids.

### Instance Key Type

This type is used for the unique ids of model instances, e.g. the `id` property of every object.
Its size determines the number of unique instances you can store in the database.
The recommendation is `UInt32`, which allows you to create 4,294,967,296 different instances for each model class.
Note that objects of different types are allowed to use the same id, since they will have different `modelId`s.

### Property Key Type

This type is used to uniquely identify each property of a model class.
It's the value provided to `@Property`, `@Reference` and `@ReferenceList`.
It should be sufficient to use `UInt8`, unless you have specific requirements about the id structure.

### Storage efficiency

The data types of the three path components is important because each property value will be stored using its own path.
This means that the appropriate selection of the data type can severely affect database performance.

### Specification

Once you have chosen good types, it's recommended to create a `typealias` to define the database to use with your models.
In the case of the provided `InMemoryDatabase`, you could write:

```swift
typealias MyDatabase = InMemoryDatabase<UInt8, UInt32, UInt8>
```

Additionally, you can define an alias for your model conformance:

```swift
typealias MyModel = Model<MyDatabase>
```

This will simplify the model definition example from [earlier](#model-definition), so that you can write:

```
final class SomeModel: MyModel {
    static let modelId: UInt8 = 1
    
}
```

If you want to write models that can be used with multiple databases, see [generic models](#generic-models).

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

### Property modification

Any of the `Property` attributes on a model can be modified as you would normally do:

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
    
    @Property(id: PropertyId.value)
    var value: String
    
    @Property(id: PropertyId.otherValue)
    var otherValue: Double
}
```

This may remind you a bit of the `CodingKey` enums in `Codable` conformances,
except that it's currently not possible to automatically assign ids.

### Generic Models

You may sometimes want to use models in different database implementations.
This is possible as long as the key paths of the databases match.

You can define a protocol that the databases for your model must conform to,
which fixes the keys:

```swift
protocol MyStorage: Database 
    where ModelKey == UInt8, 
          InstanceKey == UInt32,
          PropertyKey == UInt8 { }
```

You can then define generic models over this protocol

```swift
final class GenericModel<S: MyStorage>: Model<S> {

    static var modelId: UInt8 { 1 }
}
```

### Synchronization

It is possible to synchronize databases with each other quite easily when you supply your own database solution:
In the `set()` function of the database, copy the encoded value into a `Record`, which will provide a timestamp for the change.
Transmit the records to the database to be synchronized, and apply the updates again,
while checking for newer records.

The provided `InMemoryDatabase` offers a very basic form of synchronization for inspiration.

### Migration

There isn't much migrating to do for models in `StateModel`, since there are no fixed model schemas or other things that could produce conflicts.
Adding additional properties can be done without problems, since each new property will use the specified default if no value exists.
If the type of a property is changed, then the database will most likely not be able to decode the values anymore, which will cause the defaults to be applied.

## Database implementation

If you want to create your own database (you currently don't have a lot of other options), here is a minimal example that just caches the data in memory:

```swift
final class MinimalDatabase<Key>: Database where Key: PathKey {

    typealias KeyPath = Path<Key, Key, Key>

    private var cache: [KeyPath: Any] = [:]

    func get<Value>(_ keyPath: KeyPath) -> Value? where Value: Codable {
        cache[keyPath] as? Value
    }

    func set<Value>(_ value: Value, for path: KeyPath) where Value: Codable {
        cache[path] = value
    }

    func select<Instance: ModelProtocol>(where predicate: (Instance) -> Bool) -> [Instance] where Instance.Storage == MinimalDatabase<Key> {
        cache.compactMap { (path, value) in
            guard path.model == Instance.modelId,
                  path.property == Key.instanceId,
                  let status = value as? InstanceStatus,
                  status == .created else {
                return nil
            }
            let instance = Instance(database: self, id: path.instance)
            guard predicate(instance) else {
                return nil
            }
            return instance
        }
    }
}
```

Isn't it great that this simple database can already handle all types of models?
Based on this template, you can easily implement a history, synchronization, persistance to disk, any many optimizations based on specific paths or properties.
Go nuts!

## Roadmap

Due to the cleverly simple concept, future features will be fairly easy to add.
The following things are currently planned:

### Database implementations

A somewhat performant implementation with all the main features one might expect from a simple database.

### Update notifications

To automatically update UIs, maybe based on `ObservableObject`.

### SwiftUI support

Example databases with different underlying storage

### Non-optional references (?)

Should be possible by updating the `Reference` wrapper,
and requiring an assignment in the constructor.
But in the case there is no value in the database,
then there are limited options: Raise a fatalError, or maybe return some kind of dummy object.
Both are not great solutions, but maybe acceptable in some cases?

### Editing contexts with undo and save

That's just merging two databases

### Complete edit history

Already present, but not polished

### Viewing objects at a point in time

Mostly a matter of querying/displaying data

### Explore macros to automatically generate property ids

There might be some improvements to make for model declarations.
