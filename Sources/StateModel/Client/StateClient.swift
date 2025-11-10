import Foundation

/**
 A client to exchange data between databases.

 Use this client if data transmission is needed, since all inputs and outputs will consist of binary data.
 - SeeAlso: ``UnencodedStateClient``
 */
public struct StateClient {

    private let client: UnencodedStateClient

    public init(
        database: Database,
        decoder: any GenericDecoder,
        encoder: any GenericEncoder,
        modelMap: @escaping (ModelKey) -> (any ModelProtocol.Type)?
    ) {
        self.client = UnencodedStateClient(
            database: database,
            decoder: decoder,
            encoder: encoder,
            modelMap: modelMap
        )
    }

    // MARK: All instance updates

    /**
     Retrieve all updates to instances of a specific model.
     - Parameter model: The type of the model to query.
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: An data containing all updates.
     - Throws: `StateError` if the model id is unknown, or if the updates could not be encoded
     */
    public func instanceStatusUpdates<T: ModelProtocol>(for model: T.Type, after timestamp: Date?) throws -> InstancesData {
        try instanceStatusUpdates(for: T.modelId, after: timestamp)
    }

    /**
     Retrieve all updates to instances of a specific model.
     - Parameter model: The model id of the instances to get
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: An data containing all updates.
     - Throws: `StateError` if the model id is unknown, or if the updates could not be encoded
     */
    public func instanceStatusUpdates(for model: ModelKey, after timestamp: Date?) throws -> InstancesData {
        let updates = try client.instanceStatusUpdates(for: model, after: timestamp)
        return try client.encode(updates)
    }

    /**
     Apply updates to the instances of a model.
     - Parameter instanceUpdates: The updates to apply.
     - Throws: `StateError`, if the decoding failed, or if the model is unknown.
     */
    public func apply(instanceUpdates: InstancesData) throws {
        let decoded: InstancesUpdate = try client.decode(instanceUpdates)
        try client.apply(instanceUpdates: decoded)
    }

    // MARK: Single instance updates

    /**
     Get updates to the properties of a specific instance.
     - Parameter instance: The unique id of the instance
     - Parameter timestamp: The earliest date to consider for updates. Set to `nil` to get the full current state.
     - Returns: The data containing the requested updates
     - Throws: `CommandError`, if the model is unknown, if there is no matching instance, or if the data could not be encoded.
     */
    public func updates<T: ModelProtocol>(for instance: InstanceKey, of model: T.Type, after timestamp: Date?) throws -> InstanceData {
        try updates(for: instance, of: T.modelId, after: timestamp)
    }

    /**
     Get updates to the properties of a specific instance.
     - Parameter instance: The unique id of the instance
     - Parameter timestamp: The earliest date to consider for updates. Set to `nil` to get the full current state.
     - Returns: The data containing the requested updates
     - Throws: `CommandError`, if the model is unknown, if there is no matching instance, or if the data could not be encoded.
     */
    public func updates(for instance: InstanceKey, of model: ModelKey, after timestamp: Date?) throws -> InstanceData {
        let update = try client.updates(for: instance, of: model, after: timestamp)
        return try client.encode(update)
    }

    /**
     Decode an instance update and apply the changes.
     - Parameter instanceUpdate: The received update data.
     - Throws: `StateError`, if the update could not be decoded, or
     */
    public func apply(instanceUpdate: InstanceData) throws {
        let decoded: InstanceUpdate = try client.decode(instanceUpdate)
        try client.apply(update: decoded)
    }

    // MARK: Instance commanding

    /**
     Convert a command created by a command function to data for transmission.
     - Parameter command: The command to encode
     - Returns: The command data ready for transmission to the remote.
     - Throws: `StateError.encodingFailed` with the error from encoding
     */
    public func encode(command: StateCommand) throws -> CommandData {
        try client.encode(command)
    }

    /**
     Extract and run a received command on the local database.
     - Parameter command: The encoded command data received by the remote.
     - Throws: `StateError` if the command could not be decoded or executed
     */
    public func run(command: CommandData) throws {
        let decoded: StateCommand = try client.decode(command)
        try client.run(command: decoded)
    }

    // MARK: Any update processing

    /**
     Use this function to apply any type of data received from another client.
     */
    public func apply(data: Data) throws {
        let typeWrapper = try client.decoder.decode(ClientDataWrapper.self, from: data)
        switch typeWrapper.type {
        case .instances: try apply(instanceUpdates: data)
        case .instance: try apply(instanceUpdate: data)
        case .command: try run(command: data)
        }
    }
}
