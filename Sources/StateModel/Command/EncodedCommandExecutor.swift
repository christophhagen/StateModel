import Foundation

/**
 A command executor working with encoded arguments.

 Internally used by ``UnencodedRequestProcessor``
 */
struct EncodedCommandExecutor {

    private let command: CommandRequest

    private let decoder: any GenericDecoder

    init(command: CommandRequest, decoder: any GenericDecoder) {
        self.command = command
        self.decoder = decoder
    }

    var instance: InstanceKey {
        command.path.instance
    }

    var model: ModelKey {
        command.path.model
    }

    func argument<Value: DatabaseValue, P: RawRepresentable>(for property: P) throws(StateError) -> Value where P.RawValue == PropertyKey {
        try argument(for: property.rawValue)
    }
}

extension EncodedCommandExecutor: CommandExecutor {

    var id: PropertyKey {
        command.path.property
    }

    func argument<Value: DatabaseValue>(for property: PropertyKey) throws(StateError) -> Value {
        let encoded = try command.argument(for: property)
        do {
            return try decoder.decode(from: encoded)
        } catch {
            throw StateError.propertyDecodingFailed(property: property, error: error.localizedDescription)
        }
    }

    func commandId<P: RawRepresentable>() throws(StateError) -> P where P.RawValue == PropertyKey {
        guard let id = P.init(rawValue: command.path.property) else {
            throw StateError.unknownCommand(id: id)
        }
        return id
    }
}
