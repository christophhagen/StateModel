
/**
 A instance key is used to uniquely identify each instance of a model in the database.

 A `InstanceKeyType` must be `Codable`, `Hashable` and `Comparable`.
 The recommendation is to use integers, in order to minimize the storage overhead.
 A `UInt32` will result in a small binary representation, and allows 4,294,967,296 different instances to be stored for each model.

 The size of the instance key is important because every value of a property stored in the database will contain an instance key value alongside it.
 */
public typealias InstanceKey = Int
