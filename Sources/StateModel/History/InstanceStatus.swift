
/**
 The status of a model instance.
 */
public enum InstanceStatus: UInt8, DatabaseValue {

    /// The instance has been created in the database
    case created = 1

    /// The instance has been deleted from the database
    case deleted = 2
}

extension InstanceStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .created: "created"
        case .deleted: "deleted"
        }
    }
}
