
/**
 Types conforming to `DatabaseValue` can be stored as properties of models.

 All `Codable` types can be used.
 */
public typealias DatabaseValue = Codable

// Note: a typealias is used to later have the possibility
// to add additional requirements to the types without changing the function signature
