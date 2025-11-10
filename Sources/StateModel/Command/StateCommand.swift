import Foundation

public struct StateCommand {

    public let path: Path

    public let arguments: [PropertyKey : Data]

    public init(path: Path, arguments: [PropertyKey : Data]) {
        self.path = path
        self.arguments = arguments
    }

    /**
     Get the encoded data of an argument.
     - Parameter property: The id of the argument.
     - Throws: `StateError.missingArgument`, if no data for the argument exists.
     */
    public func argument(for property: PropertyKey) throws -> Data {
        guard let encoded = arguments[property] else {
            throw StateError.missingArgument(property)
        }
        return encoded
    }
}

extension StateCommand: Equatable {
    
}

extension StateCommand: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ClientDataType.command)
        try container.encode(path)
        try container.encode(arguments)
    }
}

extension StateCommand: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(ClientDataType.self) == .command else {
            throw StateError.invalidDataSupplied
        }
        self.path = try container.decode()
        self.arguments = try container.decode()
    }
}
