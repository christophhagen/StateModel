# StateModel

Sometimes you want to create a small data model, without worrying about database schemas, migrations, model contexts and other details.
In those cases `StateModel` may be a good choice.
It allows you to define relational models very similar to SwiftData, but with less management overhead, faster integration, and even advanced features like database synchronization and remote commands.

```swift
import StateModel

@Model(id: 1)
final class Person {

    @Property(id: 1)
    var name: String
}

let database = InMemoryDatabase()

let alice = Person.create(in: database, id: 123, name: "Alice)
```

The main idea is to flatten models into a very simple, generic structure, so that you can use a standard database without defining a complex structure.
Just define your models in code, and don't worry about tables, schemas, or any of the low-level details.
Then use your models like any other classes, while the model logic takes care of the rest.

`StateModel` has many useful features:

- Simple model definitions
- No database design needed
- SwiftUI support
- Codable support
- Editing contexts
- Edit history storage and access
- Database synchronization
- Remote commands
- Update requests

> Check out the [example app](https://github.com/christophhagen/StateModelExample) for a demonstration.

### Table of Contents

 * [Core idea](#core-idea)
 * [Installation](#installation)
 * [Model definition](#model-definition)
   * [Creating a model](#creating-a-model)
   * [SwiftUI support](#swiftui-support)
   * [Properties](#properties)
   * [References](#references)
   * [Reference Lists](#reference-lists)
 * [Database selection](#database-selection)
   * [InMemoryDatabase](#inmemorydatabase)
   * [SQLite Database](#sqlite-database)
   * [Custom implementation](#custom-implementation)
 * [Usage](#usage)
   * [Object creation](#object-creation)
   * [Properties](#properties-1)
   * [References](#references-1)
   * [Model status](#model-status)
   * [Deleted objects](#references-to-deleted-objects)
   * [Queries](#queries)
 * [Additional features](#additional-features)
   * [Caching](#caching)
   * [History view](#history-view)
   * [Editing contexts](#editing-contexts)
   * [Synchronization](#synchronization)
   * [Instance Commands](#instance-commands)
   * [Migration](#migration)
   * [Custom database implementation](#custom-database-implementation)
 * [Tips and Tricks](#tips-and-tricks)

### Core idea

A data model usually consists of different model classes, which are identified somehow (think SQLite PRIMARY KEY), and which have some properties assigned (which can point to other models).
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

### Installation

Integrate this package like you would any other:

```swift
...
    dependencies: [
        .package(url: "https://github.com/christophhagen/StateModel", from: "7.0.0")
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
 @Model(id: 1)
 final class MyModel {

     @Property(id: 42)
     var value: String
 }
 ```

You could already use this model without any additional work (apart from [choosing a database](#database-selection)).
Let's discuss the most important parts.

### Creating a model

Notice how `MyModel` has the `@Model` macro attached. 
The macro adds two properties to the type, a unique `id` for each instance, and a `database` reference.
It also conforms the type to `ModelProtocol`, which is required for each model.
Finally, the `id` parameter (`Int`) to the `@Model` macro needs to be unique for each model class, similar to how one would choose a table name for SQLite.

 > You are free to provide the requirements for `ModelProtocol` yourself, but using the `@Model` macro is usually the right choice.

### SwiftUI support

All models conform to `ObservableObject`, and can be used in SwiftUI views.
The only additional thing needed is to wrap your database to track objects and notify them of changes:

```swift
let database = MyDatabase()
let observedDatabase = ObservableDatabase(wrapping: database)
```

The wrapper is then used in all places where you would normally use the underlying database, e.g. for fetching models.
It will internally keep track of the currently used models (which conform to `ObservableObject`) and notify them whenever a property changes.

### Model attributes

Each property of the model that is backed by the database must be annotated with a property wrapper:
- `@Property(id:)` for primitives or `Codable` types
- `@Reference(id:)` for links to other models
- `@ReferenceList(id:)` for 1:n and n:n relationships

This wrapper transforms the property, so that the current values are always retrieved from the database.
This is done by using the `database` property of the model (hidden in `@Model`) with the unique path of the property.
This path is contructed from the `modelId`, the instance `id` (from `@Model`), and the `id` set for each property wrapper.

The property id must be an integer literal.
The `@Model` macro enforces unique ids for all properties, and generates a `PropertyId` enum on the type,
to access all ids programmatically, if needed.

It is still allowed to add computed properties or `let` declarations to models:

```swift
@Model(id: 1)
class MyModel {

    @Property(id: 1)
    var a: Int

    let myConstant = 42

    var shifted: Int { a + myConstant }
}
```

### Properties

The `@Property` wrapper is used to store any value that conforms to `Codable`:

```swift
@Property(id: 42)
var value: String = "Default"

@Property(id: 43)
var count: Int // Defaults to `0`
```

Every property requires a default value, which is used if the database does not contain a value for the property.
If the type conforms to `Defaultable`, then the wrapper will use the global `default` value defined for the type (e.g. `Int` conforms to `Defaultable` with default `0`), or an explicit default value must be provided.

### References

When you need to reference a single object of another model class, then `@Reference` is the way to go:

```swift
@Reference(id: 3)
var contained: NestedModel?
```

It creates a one-way reference to the object using the instance id.
The relationship is always optional, since there are no guarantees that a referenced model will be present,
and there would be no defined value when first creating a model.

Note that there is no mechanism to automatically handle inverse relationships, that's for you to manage.
There is also no possibility to specify cascading deletes.

> You may specify implicitly unwrapped optionals like `NestedModel!`, if you can guarantee that the reference can always be resolved. But be careful, as missing data will lead to runtime crashes.

### Reference Lists

Use `@ReferenceList` to handle one-to-many relationships:

```swift
@ReferenceList(id: 1)
var other: [NestedModel]
```
     
It works in a similar way as `@Reference`, and you can freely modify the list or its elements.
Internally, the list just manages an array of instance ids.
`@ReferenceList` can be used out of the box with `Array`, `Set` and `ContiguousArray`.
You can also use it with additional sequence types if you conform it to `SequenceInitializable`.

`@ReferenceList` can also be used for many-to-many relationships.
Remember that you must take care of the relationships yourself.

### Switching database implementations

You may sometimes want to use models in different database implementations,
which is supported out of the box.
This makes it possible to use different databases e.g. for testing, or to later migrate to a new database without changing the model code.

## Database selection

In addition to the definition of the models, you need to choose a database.

#### InMemoryDatabase
There is currently only one example implementation provided with `StateModel`, which keeps all data in memory.
You can directly use this database for initial testing, but production use will likely require persistence.
You can also use `InMemoryHistoryDatabase` for a full edit history.

#### SQLite Database

An implementation of a database with an underlying SQLite store is provided in [SQLiteStateDB](https://github.com/christophhagen/SQLiteStateDB).
It stores SQLite supported types (integers, doubles, strings) in separate tables, and encodes all other `Codable` values using a provided encoder.
It also provides caching of last used properties in memory, includes a history, and even has synchronization mechanism.

#### Custom implementation

You can also [write your own database](#custom-database-implementation) by inheriting from `Database`.
This gives you all the freedom to store the data in an appropriate format, implement additional features, and apply performance optimizations.

#### ID types

`StateModel` uses `Int` values for the `ModelId`, `InstanceId` and `PropertyId`.
Previous versions allowed the use of arbitrary types (e.g. `String`) that conformed to certain requirements.
This approach has been abandonned due to implementation issues with SwiftUI features, which were due to complex generics, type erasure and polymorphism.

## Usage

The models defined using `StateModel` are largely used like any other class in Swift.

### Object creation

Any object you create is part of a database.
Use the database to create or get objects.

```swift
let model: MyModel = database.create(id: 123)

let other: MyModel? = database.get(id: 123)
```

There are also generated functions to set all properties of a model at once:

```swift
 @Model(id: 1)
 final class MyModel {

     @Property(id: 42)
     var value: String
 }

let model = MyModel.create(in: database, id: 123, value: 42)
```

You should not create models outside of the database.
Since each model requires a database reference, any modification will be written to the database, 
even if the actual instance is not registered with the database.
To modify objects without writing to the database, and commiting all changes at once, see [editing contexts](#editing-contexts).

### Properties

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
If you want to ensure that reusing an id does not restore previous values, you can explicitly reset them when deleting an instance:

```swift
let instance: MyModel = ...
instance.deleteAndClearProperties()
```

This function resets each property to the default value.

### Queries

It's possible to fetch all instances of a specific type in a SwiftUI view, similar to `@Query` provided by SwiftData:

```swift
struct ContentView: View {

    @EnvironmentObject
    private var database: ObservableDatabase

    @Query
    var items: [Item]
    
    var body: some View {
        List(items) { (item: Item) in
            Text("\(item.name)")
        }
    }
}
```

The environment must provide the database object, which can be injected using `view.environmentObject(database)`.

It's also possible to directly apply filtering and sorting to the query:

```swift
@Query(filter: { $0.isCompleted }, sortBy: { $0.name })
var items: [Item]
```

### Dynamic queries

Filtering and sorting is often controlled by the user, which is why queries can be dynamically adjusted through user input.
It's possible to update the filter and sort operations by initializing a `Query` via a `QueryDescriptor`:

```swift
struct QueryView: View {

    @Query var items: [Item]

    @Binding var descriptor: QueryDescriptor<Item>

    init(descriptor: Binding<QueryDescriptor<Item>>) {
        self._items = Query(descriptor: descriptor.wrappedValue)
        self._descriptor = descriptor
    }
    
    var body: some View {
        ...
    }
}

struct ContentView: View {

    @State var descriptor: QueryDescriptor<Item> =
        .init(filter: { !$0.isCompleted },
              sortBy: { $0.sortIndex })
    
    var body: some View {
        QueryView(descriptor: $descriptor)
    }
}
```
When `descriptor` is updated, the query will automatically recompute the items.
This is similar to how SwiftData queries can be modified.
Internally, the query is recomputed when a new descriptor is provided (every call to `QueryDescriptor.init` creates a unique instance).

## Additional features

### Caching

It's easy to add caching to databases. For simple cases, it's possible combine a database with a cache using `CachedDatabase`:

```swift
let database = MyDatabase()
let cache = MaximumCountCache(maxCount: 1000)
let combined = CachedDatabase(wrapping: database, cache: cache)
```

The resulting database can then be used as it normally would.
There is a simple `MaximumCountCache` provided, but more elaborate caching can be done by implementing `DatabaseCache` manually.

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

There are use cases where information is stored in a central database, and one or more clients need to retrieve information from it.
The library provides a `StateClient` that can be used to extract the necessary information from the database:

```swift
let database: Database = ...
let client = StateClient(database: database, encoder: JSONEncoder(), decoder: JSONDecoder)

let lastSyncTime: Date = ...

// Get new and deleted instances for a specific model
let changedInstances = try client.instanceStatusUpdates(for: MyModel.self, after: lastSyncTime)

// Get property updates for an instance
let instanceId: Int = ...
let changedProperties = try client.updates(for: instanceId, of: MyModel.self, after: lastSyncTime)
```

It can also be used to apply updates received from a remote to a local database:

```swift
let local: Database = ...
let client = StateClient(database: local, encoder: JSONEncoder(), decoder: JSONDecoder)

try client.apply(instanceUpdate: changedProperties)
try client.apply(instanceUpdates: changedInstances)
```

All information to/from a `StateClient` is already encoded as `Data` (using the provided `encoder` and `decoder`), so it can directly be transmitted.

### Instance Commands

When a database is synchronized to one or more clients, there may be a need to perform actions on the instances.
The `@Command` macro can provide this functionality, so that specific functions can be invoked on instances of remote databases.

```swift
@Model(id: 1)
final class SystemPackage {
    @Property(id: 1)
    var name: String
    
    @Command(id: 2)
    func install(version: String) {
        // Install the specified version of the package
    }
}
```

With this definition, it's possible to create a command on the client, and send it to the remote:

```swift
let instance: SystemPackage = ...
let command = instance.installCommand(version: "1.0.0")
let commandData = try command.encoded(using: JSONEncoder())
```

This data can be transmitted to the remote and executed there:

```
let database: Database = ...
let client = StateClient(database: database, encoder: JSONEncoder(), decoder: JSONDecoder)
try client.run(command: commandData)
```

The client will find the targeted instance, and run the `install()` function with the correct arguments.

### Migration

There isn't much migrating to do for models in `StateModel`, since there are no fixed model schemas or other things that could produce conflicts.
Adding additional properties can be done without problems, since each new property will use the specified default if no value exists.
If the type of a property is changed, then the database will most likely not be able to decode the values anymore, which will cause the defaults to be applied.

### Custom database implementation

If you want to create your own database, here is a minimal example that just caches the data in memory:

```swift
final class MinimalDatabase: Database {

    private var cache: [Path: Any] = [:]

    // MARK: Properties

    func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        cache[path] as? Value
    }

    func set<Value: DatabaseValue>(_ value: Value, for path: Path) {
        cache[path] = value
    }

    // MARK: Instances

    func all<T>(model: ModelKey, where predicate: (_ instanceId: InstanceKey, _ value: InstanceStatus) -> T?) -> [T] {
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

## Tips and Tricks

### Model Id Enum

Each `@Model` requires a unique id, which you might want to collect in an enum:

```swift
enum ModelId: ModelKey {
    case item = 1
    case message = 2
    case reminder = 3
}
```

Then specify your models using the enum:

```swift
@Model(id: ModelId.item.rawValue)
class Item {

}
```
