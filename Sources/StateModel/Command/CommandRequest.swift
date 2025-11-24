import Foundation

public struct CommandRequest {

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
    public func argument(for property: PropertyKey) throws(StateError) -> Data {
        guard let encoded = arguments[property] else {
            throw StateError.missingArgument(id: property)
        }
        return encoded
    }
}

extension CommandRequest: Equatable {
    
}

extension CommandRequest: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(TransmissionDataType.command)
        try container.encode(path)
        try container.encode(arguments)
    }
}

extension CommandRequest: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(TransmissionDataType.self) == .command else {
            throw StateError.invalidDataSupplied
        }
        self.path = try container.decode()
        self.arguments = try container.decode()
    }
}
