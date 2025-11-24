
enum RequestType: UInt8 {

    case instanceStatus = 0

    case modelUpdate = 1

    case instanceUpdate = 2
}

extension RequestType: Codable {

}

/// Struct internally used to inspect request data for the appropriate decoding type
struct RequestTypeContainer: Decodable {

    let type: RequestType

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.type = try container.decode()
    }
}
