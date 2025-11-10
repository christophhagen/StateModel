import Foundation

/**
 A client to exchange data between databases.

 Use this client if both databases are accessible from the same code,
 i.e. if no data transmission is needed.
 - SeeAlso: ``StateClient``
 */
public struct UnencodedStateClient {

    public let database: Database

    private let modelMap: (ModelKey) -> (any ModelProtocol.Type)?

    let decoder: any GenericDecoder

    let encoder: any GenericEncoder

    public init(
        database: Database,
        decoder: any GenericDecoder,
        encoder: any GenericEncoder,
        modelMap: @escaping (ModelKey) -> (any ModelProtocol.Type)?
    ) {
        self.database = database
        self.decoder = decoder
        self.encoder = encoder
        self.modelMap = modelMap
    }

    // MARK: All instance updates

    /**
     Retrieve all updates to instances of a specific model.
     - Parameter model: The type of the instances to query.
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: An update object containing all updates.
     - Throws: `StateError.unknownModelId` if the model id is unknown
     */
    public func instanceStatusUpdates<T: ModelProtocol>(for model: T.Type, after timestamp: Date?) throws -> InstancesUpdate {
        try instanceStatusUpdates(for: T.modelId, after: timestamp)
    }

    /**
     Retrieve all updates to instances of a specific model.
     - Parameter model: The model id of the instances to get
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: An update object containing all updates.
     - Throws: `StateError.unknownModelId` if the model id is unknown
     */
    public func instanceStatusUpdates(for model: ModelKey, after timestamp: Date?) throws -> InstancesUpdate {
        guard modelMap(model) != nil else {
            throw StateError.unknownModelId(model)
        }
        guard let timestamp, let database = database as? HistoryDatabase else {
            let date = Date()
            let updates = database.all(model: model) { InstanceStatusUpdate(instance: $0, status: $1, date: date) }
            return .init(model: model, updates: updates)
        }
        let updates: [InstanceStatusUpdate] = database.all(model: model, at: nil) { instance, status, date in
            guard date > timestamp else {
                return nil
            }
            return .init(instance: instance, status: status, date: date)
        }
        return .init(model: model, updates: updates)
    }

    /**
     Apply updates to the instances of a model.
     - Parameter instanceUpdates: The updates to apply.
     - Throws: `StateError.unknownModelId`, if the model is unknown.
     */
    public func apply(instanceUpdates: InstancesUpdate) throws {
        let model = instanceUpdates.model
        guard modelMap(model) != nil else {
            throw StateError.unknownModelId(model)
        }
        guard let database = database as? HistoryDatabase else {
            for update in instanceUpdates.updates {
                let path = Path(model: model, instance: update.instance)
                database.set(update.status, for: path)
            }
            return
        }

        for update in instanceUpdates.updates {
            let path = Path(model: model, instance: update.instance)
            database.set(update.status, for: path, at: update.date)
        }
    }

    // MARK: Single instance updates

    /**
     Get updates to the properties of a specific instance.
     - Parameter instance: The unique id of the instance
     - Parameter model: The type of the instance to update.
     - Parameter timestamp: The earliest date to consider for updates. Set to `nil` to get the full current state.
     - Returns: An update object containing all requested updates
     - Throws: `CommandError`, if the model is unknown, if there is no matching instance, or if the property data could not be encoded.
     */
    public func updates<T: ModelProtocol>(for instance: InstanceKey, of model: T.Type, after timestamp: Date?) throws -> InstanceUpdate {
        try updates(for: instance, of: T.modelId, after: timestamp)
    }

    /**
     Get updates to the properties of a specific instance.
     - Parameter instance: The unique id of the instance
     - Parameter model: The model id of the instance to update.
     - Parameter timestamp: The earliest date to consider for updates. Set to `nil` to get the full current state.
     - Returns: An update object containing all requested updates
     - Throws: `CommandError`, if the model is unknown, if there is no matching instance, or if the property data could not be encoded.
     */
    public func updates(for instance: InstanceKey, of model: ModelKey, after timestamp: Date?) throws -> InstanceUpdate {
        guard let type = modelMap(model) else {
            throw StateError.unknownModelId(model)
        }
        guard database.get(id: instance, of: type) != nil else {
            throw StateError.missingInstance(instance)
        }

        let builder = InstanceUpdateBuilder(
            model: model,
            instance: instance,
            time: timestamp,
            database: database,
            encoder: encoder)

        // Set the builder as the database, so that it can record all property accesses,
        // and store them in the update.
        let instance = type.init(database: builder, id: instance)
        instance.accessAllPropertiesForUpdateCalculation()
        return try builder.update()
    }

    /**
     Apply updates received from a remote.
     - Parameter update: The received update.
     - Throws: `StateError`, if the updates could not be applied
     */
    public func apply(update: InstanceUpdate) throws {
        guard let type = modelMap(update.model) else {
            throw StateError.unknownModelId(update.model)
        }
        guard let instance = database.get(id: update.instance, of: type) else {
            throw StateError.missingInstance(update.instance)
        }
        // TODO: Prevent incomplete updates by running it in an EditingContext
        let executor = InstanceUpdateExecutor(
            model: update.model,
            instance: update.instance,
            properties: update.properties,
            decoder: decoder,
            database: database)
        try instance.apply(update: executor)
    }

    // MARK: Instance commanding

    /**
     Run a command received from a remote on the local database.
     - Parameter command: The command to execute
     - Throws: `StateError`, if the command failed to execute.
     */
    public func run(command: StateCommand) throws {
        let executor = CommandExecutor(command: command, decoder: decoder)
        guard let type = modelMap(executor.model) else {
            throw StateError.unknownModelId(executor.model)
        }
        guard let instance = database.get(id: executor.instance, of: type) else {
            throw StateError.missingInstance(executor.instance)
        }
        try instance.execute(command: executor)
    }

    // MARK: Encoding

    /**
     Extract received data
     - Parameter data: The received data
     - Returns: The decoded command
     - Throws: `StateError.decodingFailed` with the error from decoding
     */
    func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(from: data)
        } catch {
            throw StateError.decodingFailed(error)
        }
    }

    /**
     Convert a value to data for transmission.
     - Parameter command: The value to encode
     - Returns: The data ready for transmission to the remote.
     - Throws: `StateError.encodingFailed` with the error from encoding
     */
    func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw StateError.encodingFailed(error)
        }
    }
}
