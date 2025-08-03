
extension UnkeyedDecodingContainer {

    /**
     Decodes a value of a type inferred from the return type.
     - Returns: A value of the requested type, if present for the given key and convertible to the requested type.
     - Throws: `DecodingError.typeMismatch` if the encountered encoded value is not convertible to the requested type.
     - Throws: `DecodingError.valueNotFound` if the encountered encoded value is null, or of there are no more values to decode.
     */
    mutating func decode<T>() throws -> T where T : Decodable {
        try decode(T.self)
    }
}
