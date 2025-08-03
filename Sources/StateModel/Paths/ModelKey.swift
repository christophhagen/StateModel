
/**
 A model key is used to uniquely identify different model types in the database.

 A `ModelKeyType` must be `Codable`, `Hashable` and `Comparable`.
 The recommendation is to use integers, in order to minimize the storage overhead.
 A `UInt8` will result in a very small binary representation, and allows 256 different model classes to be used.

 The size of the model key is important because every value of a property stored in the database will contain a model key value alongside it.
 */
public typealias ModelKeyType = Hashable & Codable & Comparable
