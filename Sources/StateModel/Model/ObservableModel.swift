import Combine

/**
 A state model base type for models that conform to ``ObservableObject``.

 Instead of adopting the ``Model`` typealias for model definitions, use ``ObservableModel``:

 ```swift
 typealias MyModelType = ObservableModel<Int, Int, Int>

 final class MyModel: MyModelType {

 }
 ```

 It's then possible to use your model types in SwiftUI views, as they conform to ``ObservableObject``.
 Whenever a property is changed in the database, the existing object is notified about the change, redrawing SwiftUI views.

 - Note: Observing only works when wrapping a database with ``ObservableDatabase``,
 and accessing all model instances though this wrapper.
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias ObservableModel = ObservableBaseModel & ModelProtocol

/**
 The base class for model classes that are observable.
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class ObservableBaseModel: BaseModel, ObservableObject {

    public override init(database: any Database, id: BaseModel.InstanceKey) {
        super.init(database: database, id: id)
    }
}
