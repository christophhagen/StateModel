
/**
 An enum used to ensure that binary data is not accidentally decoded by the wrong function.
 */
enum TransmissionDataType: UInt8 {

    // MARK: Generic

    case error = 0

    // MARK: Responses

    /// Updates to the status of instances
    case instances = 1

    /// Updates to a single instance
    case instance = 2

    /// A command for an instance
    case command = 3

    /// Updates for multiple instances of a model
    case modelUpdates = 4

    // MARK: Requests

    case instanceStatusRequest = 10

    case modelUpdateRequest = 11

    case instanceUpdateRequest = 12
}

extension TransmissionDataType: Codable {
    
}


/// A dummy struct used to decode a `TransmissionDataType`
struct TransmissionDataIndicator: Decodable {

    let type: TransmissionDataType

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.type = try container.decode()
    }
}
