import Foundation

/**
 A decoder type that can decode `Codable` types from binary data.
 */
public protocol GenericDecoder {

    /**
     Returns a value of the type you specify, decoded from the binary data.
     - Parameter type: The type of the value to decode from the supplied JSON object.
     - Parameter data: The binary data to decode.
     - Returns: A value of the specified type, if the decoder can parse the data.
     - Throws: Errors of type ``DecodingError``
     */
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}

public extension GenericDecoder {

    /**
     Returns a value of the type you specify, decoded from the binary data.
     - Parameter data: The binary data to decode.
     - Returns: A value of the specified type, if the decoder can parse the data.
     - Throws: Errors of type ``DecodingError``
     */
    func decode<T>(from data: Data) throws -> T where T: Decodable {
        try decode(T.self, from: data)
    }
}
