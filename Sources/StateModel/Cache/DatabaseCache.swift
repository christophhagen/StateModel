import Foundation

/**
 A cache that can be used with a SQLite database.
 */
public protocol DatabaseCache {

    /**
     Get the value for a property, if it is present in the cache
     - Parameter path: The path of the property
     - Returns: The value of the property, if one exists in the cache
     */
    func get<Value: DatabaseValue>(_ path: Path) -> Value?

    /**
     Insert/update the value for a property.
     - Parameter value: The new value to set for the property
     - Parameter path: The path of the property
     */
    func set<Value: DatabaseValue>(_ value: Value, for path: Path)

}
