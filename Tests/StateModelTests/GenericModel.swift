import StateModel

protocol EfficientDatabase: Database where ModelKey == UInt8, InstanceKey == UInt32, PropertyKey == UInt8 {

}

final class GenericModel<S: EfficientDatabase>: Model<S> {

    static var modelId: UInt8 { 1 }

    @Property(1)
    var some: Int = 1
}

extension Property where PropertyKey == UInt8, Value: Defaultable {

    init(wrappedValue: Value, _ id: UInt8) {
        self.init(wrappedValue: wrappedValue, id: id)
    }
}
