import Foundation
import StateModel

/**
 A simple database implementation that only caches the latest values in memory
 */
final class MinimalDatabase<Key>: Database where Key: PathKey {

    typealias KeyPath = Path<Key, Key, Key>

    private var cache: [KeyPath: Any] = [:]

    // MARK: Properties

    func get<Value>(_ keyPath: KeyPath) -> Value? where Value: Codable {
        cache[keyPath] as? Value
    }

    func set<Value>(_ value: Value, for path: KeyPath) where Value: Codable {
        cache[path] = value
    }

    // MARK: Instances

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    func select<Instance>(where predicate: (Instance) -> Bool) -> [Instance] where Instance: ModelProtocol, Instance.Storage == MinimalDatabase<Key> {
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
