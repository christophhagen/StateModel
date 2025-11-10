import Foundation

public struct CommandExecutor {

    private let command: StateCommand

    private let decoder: any GenericDecoder

    public init(command: StateCommand, decoder: any GenericDecoder) {
        self.command = command
        self.decoder = decoder
    }

    public func argument<Value>(for property: PropertyKey) throws -> Value where Value: DatabaseValue {
        let encoded = try command.argument(for: property)
        do {
            return try decoder.decode(from: encoded)
        } catch {
            throw StateError.propertyDecodingFailed(property, error)
        }
    }

    public func commandId<P: RawRepresentable>() throws -> P where P.RawValue == PropertyKey {
        guard let id = P.init(rawValue: command.path.property) else {
            throw StateError.unknownCommandId(id)
        }
        return id
    }

    var id: PropertyKey {
        command.path.property
    }

    var instance: InstanceKey {
        command.path.instance
    }

    var model: ModelKey {
        command.path.model
    }

    public func argument<Value, P: RawRepresentable>(for property: P) throws -> Value where Value: DatabaseValue, P.RawValue == PropertyKey {
        try argument(for: property.rawValue)
    }
}
