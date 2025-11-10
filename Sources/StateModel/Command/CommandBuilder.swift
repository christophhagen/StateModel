import Foundation

public final class CommandBuilder {

    private let path: Path

    private var arguments: [PropertyKey : (GenericEncoder) throws -> Data] = [:]

    public init(path: Path) {
        self.path = path
    }

    public func add<Value>(_ value: Value, for property: PropertyKey) where Value: DatabaseValue {
        arguments[property] = {
            do {
                return try $0.encode(value)
            } catch {
                throw StateError.argumentEncodingFailed(property, error)
            }
        }
    }

    public func add<Value, P: RawRepresentable>(_ value: Value, for property: P) where Value: DatabaseValue, P.RawValue == PropertyKey {
        add(value, for: property.rawValue)
    }

    public func command(using encoder: any GenericEncoder) throws -> StateCommand {
        let encodedArguments = try arguments.mapValues { encodingFunction in
            try encodingFunction(encoder)
        }
        return .init(path: path, arguments: encodedArguments)
    }

    public func encoded(using encoder: any GenericEncoder) throws -> Data {
        let command = try command(using: encoder)
        do {
            return try encoder.encode(command)
        } catch {
            throw StateError.encodingFailed(error)
        }
    }
}
