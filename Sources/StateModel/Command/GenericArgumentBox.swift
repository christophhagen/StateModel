import Foundation

protocol GenericArgumentBox {

    var property: PropertyKey { get }

    func encode(using encoder: any GenericEncoder) throws(StateError) -> Data

    func get<V>(as type: V.Type) -> V?
}
