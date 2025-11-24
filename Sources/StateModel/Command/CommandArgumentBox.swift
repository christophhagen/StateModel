import Foundation

struct CommandArgumentBox<T: Encodable>: GenericArgumentBox {

    let property: PropertyKey

    let value: T

    func encode(using encoder: any GenericEncoder) throws(StateError) -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw StateError.argumentEncodingFailed(id: property, error: error.localizedDescription)
        }
    }

    func get<Value>(as type: Value.Type) -> Value? {
        value as? Value
    }
}
