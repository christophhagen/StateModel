import Foundation
#if canImport(Combine)
import Combine
#else
import OpenCombine
#endif

/**
 A database wrapper to enable the use of observable models.

 Wrap any existing database to allow tracking of object references, which are notified about changes to properties.

 ```swift
 let database = MyDatabase()
 let observingDatabase = ObservableDatabase(wrapping: database)
 ```
 The database ensures that only a single object is used throughout all operations for each instance of a model.
 Whenever a property is changed in the database, the singular object is notified about the change, redrawing SwiftUI views.
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class ObservableDatabase: Database, ObservableObject {

    // MARK: Internal types

    public typealias Wrapped = Database

    public typealias KeyPath = Path

    /// A key for the observed object cache
    private struct ObjectKey: Hashable {
        let model: ModelKey
        let instance: InstanceKey
    }

    /// A weak box for caching
    private class WeakBox<T: AnyObject> {
        weak var value: T?
        init(_ value: T) { self.value = value }
    }

    // MARK: Life cycle

    private let wrapped: Wrapped

    /**
     Create an observing database by wrapping another database.
     - Parameter wrapped: The database to observe.
     */
    public init(wrapping wrapped: Database) {
        self.wrapped = wrapped
    }

    // MARK: Instance caching and notification

    private typealias ObservedModel = ObservableObject & ModelInstance

    private struct WeakModel {
        weak var value: (any ObservedModel)?
        init(_ value: any ObservedModel) { self.value = value }
    }

    private var storage: [ObjectKey : WeakModel] = [:]

    private var numberOfObjectsInsertedAfterLastCleanup = 0

    private let numberOfInsertionsBetweenCleanup = 1000

    private func getCached(model: ModelKey, instance: InstanceKey) -> (any ObservedModel)? {
        let id = ObjectKey(model: model, instance: instance)
        guard let box = storage[id] else {
            return nil
        }
        if box.value == nil {
            storage[id] = nil
            return nil
        }
        return box.value
    }

    private func cache(_ object: any ObservedModel, model: ModelKey, instance: InstanceKey) {
        storage[ObjectKey(model: model, instance: instance)] = WeakModel(object)
        numberOfObjectsInsertedAfterLastCleanup += 1
        // Remove boxes for deallocated objects
        if numberOfObjectsInsertedAfterLastCleanup >= numberOfInsertionsBetweenCleanup {
            cleanup()
            numberOfObjectsInsertedAfterLastCleanup = 0
        }
    }

    private func getCachedOrCreate<T: ModelProtocol>(instance: InstanceKey, notifyExisting: Bool = false) -> T {
        let model = T.modelId
        if let existing = getCached(model: model, instance: instance) as? T {
            if notifyExisting {
                (existing.objectWillChange as? ObservableObjectPublisher)?.send()
            }
            return existing
        }
        let object = T(database: self, id: instance)
        cache(object, model: model, instance: instance)
        return object
    }

    /**
     Notify an instance that the underlying data has changed.

     The single object matching the model and instance id will be informed about changes via `objectWillChange`.
     All queries that include the instance will also be notified.

     This function is internally by `ObservableDatabase` to notify instances about changes to the data.
     It can also be called manually if changes to the database are made without using the standard mechanisms,
     e.g. when injecting synchronization data.
     - Parameter model: The id of the model class that was updated.
     - Parameter instance: The id of the updated instance.
     */
    public func updateChangedObject(model: ModelKey, instance: InstanceKey) {
        notifyChangedObject(model: model, instance: instance)
#if canImport(SwiftUI)
        notifyChangedQueries(model: model, instance: instance)
#endif
    }

    private func notifyChangedObject(model: ModelKey, instance: InstanceKey) {
        let id = ObjectKey(model: model, instance: instance)
        guard let box = storage[id] else {
            return
        }
        guard let object = box.value else {
            storage[id] = nil
            return
        }
        (object.objectWillChange as? ObservableObjectPublisher)?.send()
    }

    private func cleanup() {
        let deadKeys = storage.filter { $0.value.value == nil }.map(\.key)
        for key in deadKeys {
            storage.removeValue(forKey: key)
        }
    }

    // MARK: Query caching and notification

#if canImport(SwiftUI)
    private struct Observer {

        weak var observer: QueryObserver?

        let predicate: (InstanceKey, InstanceStatus) -> Bool
    }

    private var cachedQueries: [ModelKey : [WeakBox<QueryObserver>]] = [:]

    public func queryAll<Instance: ModelProtocol>(observer: QueryObserver, where predicate: ((Instance) -> Bool)?) -> [Instance] {
        guard let predicate else {
            return queryAll(observer: observer)
        }
        let model = Instance.modelId
        // Register query to notify on future changes
        cachedQueries[model, default: []].append(.init(observer))
        return wrapped.all(model: model) { instanceId, status in
            guard status == .created else {
                return nil
            }
            // We first construct an instance to test against the predicate
            // and only get or create the observed object if it's actually needed
            let instance = Instance(database: self, id: instanceId)
            guard predicate(instance) else {
                return nil
            }
            if let cached = self.getCached(model: model, instance: instanceId) as? Instance {
                return cached
            }
            cache(instance, model: model, instance: instanceId)
            return instance
        }
    }

    public func queryAll<Instance: ModelProtocol>(observer: QueryObserver) -> [Instance] {
        let model = Instance.modelId
        // Register query to notify on future changes
        cachedQueries[model, default: []].append(.init(observer))
        return wrapped.all(model: model) { instanceId, status in
            guard status == .created else {
                return nil
            }
            if let cached = self.getCached(model: model, instance: instanceId) as? Instance {
                return cached
            }
            let instance = Instance(database: self, id: instanceId)
            cache(instance, model: model, instance: instanceId)
            return instance
        }
    }

    private func notifyChangedQueries(model: ModelKey, instance: InstanceKey) {
        guard let queries = cachedQueries[model] else {
            return
        }
        var needsCleaning = false
        for box in queries {
            guard let observer = box.value else {
                needsCleaning = true
                continue
            }
            observer.didUpdate(instance: instance)
        }
        guard needsCleaning else {
            return
        }
        cachedQueries[model] = queries.filter { $0.value != nil }
    }
#endif

    // MARK: Database

    public func get<Value: DatabaseValue>(_ path: KeyPath) -> Value? {
        wrapped.get(path)
    }

    public func set<Value: DatabaseValue>(_ value: Value, for path: KeyPath) {
        wrapped.set(value, for: path)
        updateChangedObject(model: path.model, instance: path.instance)
    }

    public func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        // Note: We need to check if the type is observable,
        // because T is not restricted, and users may produce non-observable results
        guard T.self is (any ObservedModel.Type) else {
            return wrapped.all(model: model, where: predicate)
        }
        // Find previous instances and return them, to only have a single object
        // that receives update notifications
        return wrapped.all(model: model) { instance, status in
            guard let object: T = predicate(instance, status) else {
                return nil
            }
            // Note: The actual object returned by the predicate may be replaced
            // if a cached version of the object exists
            // This is needed to ensure that objects are properly notified about changes,
            // but it may break complex scenarios where the user initializes `object` in a
            // non-trivial way (with custom internal state not stored in the database)
            if let cached = self.getCached(model: model, instance: instance) as? T {
                return cached
            }
            // We can force-cast here, since we checked in the beginning that T is an ObservableObject
            cache(object as! (any ObservedModel), model: model, instance: instance)
            return object
        }
    }

    // MARK: Instances

    /**
     Create a new instance.

     This function will set the instance status of the provided id to `created`,
     and return the instance.

     - Parameter id: The instance id
     - Parameter type: The type of model to create.
     - Returns: A new model instance of the specified type with the given id.
     */
    public func create<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance {
        set(InstanceStatus.created, model: Instance.modelId, instance: id, property: PropertyKey.instanceId)
        // If an existing object is passed to this function, notify it about the status change
        return getCachedOrCreate(instance: id, notifyExisting: true)
    }

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    public func get<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance? {
        guard get(model: Instance.modelId, instance: id, property: PropertyKey.instanceId, of: InstanceStatus.self) != nil else {
            return nil
        }
        return getCachedOrCreate(instance: id)
    }

    /**
     Get an instance via its id, if it exists and is not deleted.
     - Parameter id: The instance id
     - Parameter type: The type of the model
     - Returns: The existing, non-deleted instance, or `nil`
     */
    public func active<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance? {
        guard let status: InstanceStatus = get(model: Instance.modelId, instance: id, property: PropertyKey.instanceId), status == .created else {
            return nil
        }
        return getCachedOrCreate(instance: id)
    }

    /**
     Delete a specific instance.
     - Parameter instance: The instance to delete
     */
    public func delete<Instance: ModelProtocol>(_ instance: Instance) {
        set(InstanceStatus.deleted, model: Instance.modelId, instance: instance.id, property: PropertyKey.instanceId)
        // Notify instance about deletion status
        (instance.objectWillChange as? ObservableObjectPublisher)?.send()
    }

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    public func all<Instance: ModelProtocol>(where predicate: (Instance) -> Bool) -> [Instance] {
        return all(model: Instance.modelId) { instanceId, status in
            guard status == .created else {
                return nil
            }
            // Note: We don't need to check the cache or observe the instance here
            // because it will be replaced by the all(model:where:) function when returned
            let instance = Instance(database: self, id: instanceId)
            guard predicate(instance) else {
                return nil
            }
            return instance
        }
    }
}
