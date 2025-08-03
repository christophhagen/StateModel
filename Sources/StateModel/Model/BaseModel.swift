
/**
 A basic model to subclass which contains a database reference and an instance id.
 */
open class BaseModel<Storage> where Storage: Database {

    /// The reference to the model database to read and write property values
    public unowned let database: Storage

    /// The unique id of the instance
    public let id: Storage.InstanceKey

    /**
     Create a model.
     - Parameter database: The reference to the model database to read and write property values
     - Parameter id: The unique id of the instance
     */
    public init(database: Storage, id: Storage.InstanceKey) {
        self.database = database
        self.id = id
    }
}

extension BaseModel: Equatable {

    public static func == (lhs: BaseModel<Storage>, rhs: BaseModel<Storage>) -> Bool {
        lhs.id == rhs.id
    }
}
