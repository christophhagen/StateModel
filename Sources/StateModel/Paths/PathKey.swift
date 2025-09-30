
/**
 A `PathKey` can be used for any of the three parts of a ``Path``.

 It is used to uniquely identify the model type, the instances of a model, and the properties of each instance.

 A `PathKey` must be `Codable`, `Hashable` and `Comparable`.
 It also must provide a static `instanceId`, see ``InstanceKeyType.instanceId``.

 The recommendation is to use integers, in order to minimize the storage overhead.
 In order to maximize storage efficiency, it is recommended to use different and appropriate types for each ``Path`` component.
 The `PathKey` typealias is mostly provided for convenience and getting started.

 The size of the path key is important because every value of a property stored in the database will contain a path alongside it, which consists of three `PathKey` components.
 */
public typealias PathKey = Int
