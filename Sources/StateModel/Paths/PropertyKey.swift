
/**
 A property key is used to uniquely identify the properties of models in the database.

 A `PropertyKeyType` must be `Codable`, `Hashable` and `Comparable`.
 The recommendation is to use integers, in order to minimize the storage overhead.
 A `UInt8` will result in a very small binary representation, and allows 255 different properties to be used.

 The size of the model key is important because every value of a property stored in the database will contain a property key value alongside it.
 */
public protocol PropertyKeyType: Hashable, Comparable, DatabaseValue {

    /**
     The unique id to use when storing information about the instance itself,
     e.g. whether an object is deleted or created.

     - Warning: This id must not be used when assigning ids to new instances, otherwise data corruption will occur.

     When an object is created in the database, then the `instanceId` is used to store the state of the instance ( `created`),
     so that all existing elements of the type can be queried.
     Similarly, when an instance is deleted, then the new state `deleted` is stored using the `instanceId` as the ``Path.property`` key.
     */
    static var instanceId: Self { get }
}

public typealias PropertyKey = Int
