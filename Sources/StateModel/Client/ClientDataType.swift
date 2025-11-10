
/**
 An enum used to ensure that binary data is not accidentally decoded by the wrong function.
 */
enum ClientDataType: UInt8 {

    /// Updates to the status of instances
    case instances = 1

    /// Updates to a single instance
    case instance = 2

    /// A command for an instance
    case command = 3
}

extension ClientDataType: Codable {
    
}


struct ClientDataWrapper: Decodable {

    let type: ClientDataType

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.type = try container.decode()
    }
}
