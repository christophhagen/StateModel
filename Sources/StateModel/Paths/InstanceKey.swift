
/**
 A instance key is used to uniquely identify each instance of a model in the database.

 It is currently specified to be an integer.
 */
public typealias InstanceKey = Int


public extension InstanceKey {

    /**
     Create a random instance id over the full range.
     */
    static func random() -> Self {
        .random(in: Self.min...Self.max)
    }
}
