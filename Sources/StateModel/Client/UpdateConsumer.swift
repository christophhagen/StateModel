import Foundation

/**
 A client to exchange data between databases.

 Use this client if data transmission is needed, since all inputs and outputs will consist of binary data.
 - SeeAlso: ``UnencodedUpdateConsumer``
 */
public struct UpdateConsumer {

    private let consumer: UnencodedUpdateConsumer

    private let encoder: any GenericEncoder

    private let decoder: any GenericDecoder

    public init(
        database: Database,
        encoder: any GenericEncoder,
        decoder: any GenericDecoder,
        modelMap: @escaping (ModelKey) -> (any ModelProtocol.Type)?
    ) {
        self.encoder = encoder
        self.decoder = decoder
        self.consumer = UnencodedUpdateConsumer(
            database: database,
            decoder: decoder,
            encoder: encoder,
            modelMap: modelMap
        )
    }

    // MARK: Instance status updates

    /**
     Create a request for updates to instances of a specific model.
     - Parameter model: The type of the model to query.
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: The request data to process by the remote.
     - Throws: `StateError` if the request could not be encoded
     */
    public func instanceStatusRequest<T: ModelProtocol>(for model: T.Type, after timestamp: Date?) throws -> InstanceStatusRequestData {
        try instanceStatusRequest(for: model.modelId, after: timestamp)
    }

    /**
     Create a request for updates to instances of a specific model.
     - Parameter model: The model id to query.
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: The request data to process by the remote.
     - Throws: `StateError` if the request could not be encoded
     */
    public func instanceStatusRequest(for model: ModelKey, after timestamp: Date?) throws -> InstanceStatusRequestData {
        let request = consumer.instanceStatusRequest(for: model, after: timestamp)
        return try encode(request)
    }

    /**
     Apply updates to the instances of a model.
     - Parameter instanceUpdates: The updates to apply.
     - Throws: `StateError`, if the decoding failed, or if the model is unknown.
     */
    public func apply(instanceUpdates: InstancesData) throws {
        let decoded: InstancesUpdate = try decode(instanceUpdates)
        try consumer.apply(instanceUpdates: decoded)
    }

    // MARK: All instance updates

    /**
     Request all updates for a specific model.

     The response of a producer will always include all updates of a specific instance, so that queries can be completed at that point.
     When continuing a
     - Parameter model: The model for which to request updates.
     - Parameter timestamp: The point in time after which updates should be considered.
     - Parameter limit: The maximum number of updates to add in the response.
     - Parameter instance: The instance to start at, to continue previous requests.
     - Throws: `StateError.encodingFailed`, if the request could not be encoded.
     */
    public func modelUpdateRequest<T: ModelProtocol>(for model: T.Type, after timestamp: Date?, limit: Int, startingAt instance: InstanceKey? = nil) throws(StateError) -> ModelUpdateRequestData {
        try modelUpdateRequest(for: T.modelId, after: timestamp, limit: limit, startingAt: instance)
    }

    /**
     Request all updates for a specific model.

     The response of a producer will always include all updates of a specific instance, so that queries can be completed at that point.
     When continuing a
     - Parameter model: The model id for which to request updates.
     - Parameter timestamp: The point in time after which updates should be considered.
     - Parameter limit: The maximum number of updates to add in the response.
     - Parameter instance: The instance to start at, to continue previous requests.
     - Throws: `StateError.encodingFailed`, if the request could not be encoded.
     */
    public func modelUpdateRequest(for model: ModelKey, after timestamp: Date?, limit: Int, startingAt instance: InstanceKey? = nil) throws(StateError) -> ModelUpdateRequestData {
        let request = consumer.modelUpdateRequest(for: model, after: timestamp, limit: limit, startingAt: instance)
        return try encode(request)
    }

    /**
     Apply updates requested via `modelUpdateRequest()`.
     */
    public func apply(modelUpdates: ModelUpdateData) throws -> InstanceKey? {
        let decoded: ModelUpdate = try decode(modelUpdates)
        return try consumer.apply(modelUpdates: decoded)
    }

    // MARK: Single instance updates

    /**
     Get updates to the properties of a specific instance.
     - Parameter instance: The unique id of the instance
     - Parameter timestamp: The earliest date to consider for updates. Set to `nil` to get the full current state.
     - Returns: The data containing the requested updates
     - Throws: `CommandError`, if the model is unknown, if there is no matching instance, or if the data could not be encoded.
     */
    public func instanceUpdateRequest<T: ModelProtocol>(for instance: InstanceKey, of model: T.Type, after timestamp: Date?) throws -> InstanceUpdateRequestData {
        try instanceUpdateRequest(for: instance, of: T.modelId, after: timestamp)
    }

    /**
     Get updates to the properties of a specific instance.
     - Parameter instance: The unique id of the instance
     - Parameter timestamp: The earliest date to consider for updates. Set to `nil` to get the full current state.
     - Returns: The data containing the requested updates
     - Throws: `CommandError`, if the model is unknown, if there is no matching instance, or if the data could not be encoded.
     */
    public func instanceUpdateRequest(for instance: InstanceKey, of model: ModelKey, after timestamp: Date?) throws -> InstanceUpdateRequestData {
        let request = consumer.instanceUpdateRequest(for: instance, of: model, after: timestamp)
        return try encode(request)
    }

    /**
     Decode an instance update and apply the changes.
     - Parameter instanceUpdate: The received update data.
     - Throws: `StateError`, if the update could not be decoded, or
     */
    public func apply(instanceUpdate: InstanceUpdateData) throws(StateError) {
        let decoded: InstanceUpdate = try decode(instanceUpdate)
        try consumer.apply(instanceUpdate: decoded)
    }

    // MARK: Instance commanding

    /**
     Convert a command created by a command function to data for transmission.
     - Parameter command: The command to encode
     - Returns: The command data ready for transmission to the remote.
     - Throws: `StateError.encodingFailed` with the error from encoding
     */
    public func encode(command: CommandBuilder) throws(StateError) -> CommandRequestData {
        let result = try consumer.encode(command: command)
        return try encode(result)
    }

    /**
     Throw an error from a command execution response.
     - Parameter commandResponse: The response received from the request processor.
     - Throws: `StateError`, if the command was unsuccessful.
     */
    public func decode(commandResponse: CommandResponseData) throws(StateError) {
        let result: StateError = try decode(commandResponse)
        if case .success = result { return }
        throw result
    }

    // MARK: Generic processing

    /**
     Use this function to apply any type of data received from another client.
     */
    public func apply(data: Data) throws {
        let typeWrapper: TransmissionDataIndicator = try decode(data)
        switch typeWrapper.type {
        case .instances: try apply(instanceUpdates: data)
        case .instance: try apply(instanceUpdate: data)
        case .modelUpdates: _ = try apply(modelUpdates: data)
        default:
            throw StateError.invalidDataSupplied
        }
    }
    
    // MARK: Encoding

    /**
     Extract received data
     - Parameter data: The received data
     - Returns: The decoded command
     - Throws: `StateError.decodingFailed` with the error from decoding
     */
    private func decode<T: Decodable>(_ data: Data) throws(StateError) -> T {
        do {
            return try decoder.decode(from: data)
        } catch {
            throw StateError.decodingFailed(error: error.localizedDescription)
        }
    }

    /**
     Convert a value to data for transmission.
     - Parameter command: The value to encode
     - Returns: The data ready for transmission to the remote.
     - Throws: `StateError.encodingFailed` with the error from encoding
     */
    private func encode<T: Encodable>(_ value: T) throws(StateError) -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw StateError.encodingFailed(error: error.localizedDescription)
        }
    }
}
