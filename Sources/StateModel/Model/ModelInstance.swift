
public protocol ModelInstance: AnyObject, Identifiable, Hashable {

    /**
     The unique id of the instance.

     This id must be unique among all instances of the type.
     The id is used as the second part of the key path.
     */
    var id: InstanceKey { get }

    /**
     A reference to the database where the model is persisted.

     This reference should be `unowned` to not create retain cycles.
     */
    var database: Database { get }

    /**
     Create a new instance.
     */
    init(database: Database, id: InstanceKey)
}


extension ModelInstance {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension ModelInstance {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

