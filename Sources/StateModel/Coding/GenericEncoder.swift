import Foundation

/**
 An encoder type that can encode `Codable` values to binary data.
 */
public protocol GenericEncoder {

    /**
     Returns a binary-encoded representation of the value you supply.
     - Parameter value: The value to encode as binary data.
     - Returns: The encoded data.
     - Throws: Errors of type ``EncodingError``
     */
    func encode<T>(_ value: T) throws -> Data where T: Encodable
}
