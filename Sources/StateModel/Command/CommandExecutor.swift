import Foundation

public protocol CommandExecutor {

    var id: PropertyKey { get }

    func argument<Value>(for property: PropertyKey) throws(StateError) -> Value where Value: DatabaseValue

    func commandId<P: RawRepresentable>() throws(StateError) -> P where P.RawValue == PropertyKey
}
