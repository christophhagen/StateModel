import Foundation

/**
 A provider to process requests from clients.

 Use this provider if data transmission is needed, since all inputs and outputs will consist of binary data.
 - SeeAlso: ``UnencodedRequestProcessor``
 */
public struct RequestProcessor {

    /// The database to use when processing requests
    private let provider: UnencodedRequestProcessor

    /// The encoder used to encode property values and responses
    private let encoder: any GenericEncoder

    /// The decoder used to decode command arguments and requests
    private let decoder: any GenericDecoder

    /**
     - Parameter database: The database to use when processing requests
     - Parameter encoder: The encoder used to encode property values and responses
     - Parameter decoder: The decoder used to decode command arguments and requests
     - Parameter modelMap: A mapping of all model ids to their associated types
     */
    public init(
        database: Database,
        encoder: any GenericEncoder,
        decoder: any GenericDecoder,
        modelMap: @escaping (ModelKey) -> (any ModelProtocol.Type)?
    ) {
        self.decoder = decoder
        self.encoder = encoder
        self.provider = UnencodedRequestProcessor(
            database: database,
            encoder: encoder,
            decoder: decoder,
            modelMap: modelMap
        )
    }

    // MARK: Instance status updates

    /**
     Retrieve all updates to instances of a specific model.
     - Parameter request: The request specifying the data to retrieve.
     - Returns: Data containing all updates.
     - Throws: `StateError` if the updates could not be encoded or decoded
     */
    public func process(instanceStatusRequest request: InstanceStatusRequestData) throws(StateError) -> InstancesData {
        try decode(InstanceStatusRequest.self, from: request) { decoded in
            provider.instanceStatusUpdates(for: decoded)
        }
    }

    // MARK: All instance updates

    public func process(modelUpdateRequest request: ModelUpdateRequestData) throws(StateError) -> ModelUpdateData {
        try decode(ModelUpdateRequest.self, from: request) { decoded in
            provider.allUpdates(for: decoded)
        }
    }

    // MARK: Single instance updates

    public func process(instanceUpdateRequest request: InstanceUpdateRequestData) throws(StateError) -> InstanceUpdateData {
        try decode(InstanceUpdateRequest.self, from: request) { decoded in
            provider.process(instanceUpdateRequest: decoded)
        }
    }

    // MARK: Instance commanding

    /**
     Extract and run a received command on the local database.
     - Parameter command: The encoded command data received by the remote.
     - Throws: `StateError` if a command error occured and could not be encoded
     - Returns: An encoded `StateError`, with`StateError.success`, if the command executed successfully.
     */
    public func process(command: CommandRequestData) throws(StateError) -> CommandResponseData {
        try decode(CommandRequest.self, from: command) { decoded in
            provider.process(command: decoded)
        }
    }

    // MARK: Generic processing

    public func process(request: Data) throws(StateError) -> Data {
        let typeIndicator: RequestTypeContainer
        do {
            typeIndicator = try decoder.decode(from: request)
        } catch {
            let decodingError = StateError.decodingFailed(error: error.localizedDescription)
            return try encodeOrThrow(decodingError)
        }
        return switch typeIndicator.type {
        case .instanceStatus: try process(instanceStatusRequest: request)
        case .modelUpdate: try process(modelUpdateRequest: request)
        case .instanceUpdate: try process(instanceUpdateRequest: request)
        }
    }

    // MARK: Encoding

    /**
     Extract received data
     - Parameter data: The received data
     - Returns: The result data
     - Throws: `StateError.encodingFailed` with the error from encoding, or `StateError.decodingFailed` with an error from decoding
     */
    private func decode<D: Decodable, E: Encodable>(_ type: D.Type = D.self, from data: Data, perform: (D) -> E) throws(StateError) -> Data {
        let decoded: D
        do {
            decoded = try decoder.decode(from: data)
        } catch {
            let decodingError = StateError.decodingFailed(error: error.localizedDescription)
            return try encodeOrThrow(decodingError)
        }
        let result = perform(decoded)

        // Encode the result, encode an error, or throw as a last resort
        do {
            return try encoder.encode(result)
        } catch {
            let convertedError = StateError.encodingFailed(error: error.localizedDescription)
            return try encodeOrThrow(convertedError)
        }
    }

    private func encodeOrThrow(_ error: StateError) throws(StateError) -> Data {
        do {
            return try encoder.encode(error)
        } catch _ {
            throw error
        }
    }
}
