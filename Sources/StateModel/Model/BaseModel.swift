
/**
 A basic model to subclass which contains a database reference and an instance id.
 */
open class BaseModel<ModelKey, InstanceKey, PropertyKey> where ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType {

    /// The reference to the model database to read and write property values
    public unowned let database: Database<ModelKey, InstanceKey, PropertyKey>

    /// The unique id of the instance
    public let id: InstanceKey

    /**
     Create a model.
     - Parameter database: The reference to the model database to read and write property values
     - Parameter id: The unique id of the instance
     */
    public init(database: Database<ModelKey, InstanceKey, PropertyKey>, id: InstanceKey) {
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
