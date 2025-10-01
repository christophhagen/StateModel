
/**
 A basic model to subclass which contains a database reference and an instance id.
 */
open class BaseModel: ModelInstance {

    /// The reference to the model database to read and write property values
    public unowned let database: Database

    /// The unique id of the instance
    public let id: InstanceKey

    /**
     Create a model.
     - Parameter database: The reference to the model database to read and write property values
     - Parameter id: The unique id of the instance
     */
    public required init(database: Database, id: InstanceKey) {
        self.database = database
        self.id = id
    }
}

extension BaseModel: Identifiable {

}

extension BaseModel: Equatable {

    public static func == (lhs: BaseModel, rhs: BaseModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension BaseModel: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
