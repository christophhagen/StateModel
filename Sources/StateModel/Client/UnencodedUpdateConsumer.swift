import Foundation

/**
 A client to exchange data between databases.

 Use this client if both databases are accessible from the same code,
 i.e. if no data transmission is needed.
 - SeeAlso: ``UpdateConsumer``
 */
public struct UnencodedUpdateConsumer {

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
     Create a request for updates to instances of a specific model.
     - Parameter model: The model to query.
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: The request data to process by the remote.
     */
    public func instanceStatusRequest<T: ModelProtocol>(for model: T.Type, after timestamp: Date?) -> InstanceStatusRequest {
        .init(model: model.modelId, timestamp: timestamp)
    }

    /**
     Create a request for updates to instances of a specific model.
     - Parameter model: The model id to query.
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: The request data to process by the remote.
     */
    public func instanceStatusRequest(for model: ModelKey, after timestamp: Date?) -> InstanceStatusRequest {
        .init(model: model, timestamp: timestamp)
    }

    /**
     Apply updates to the instances of a model.
     - Parameter instanceUpdates: The updates to apply.
     - Throws: `StateError.unknownModelId`, if the model is unknown.
     */
    public func apply(instanceUpdates: InstancesUpdate) throws(StateError) {
        let model = instanceUpdates.model
        guard modelMap(model) != nil else {
            throw StateError.unknownModel(id: model)
        }
        guard let database = database as? TimestampedDatabase else {
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

    public func modelUpdateRequest<T: ModelProtocol>(for model: T.Type, after timestamp: Date?, limit: Int, startingAt instance: InstanceKey? = nil) -> ModelUpdateRequest {
        modelUpdateRequest(for: T.modelId, after: timestamp, limit: limit, startingAt: instance)
    }

    public func modelUpdateRequest(for model: ModelKey, after timestamp: Date?, limit: Int, startingAt instance: InstanceKey? = nil) -> ModelUpdateRequest {
        .init(model: model, timestamp: timestamp, limit: limit, instance: instance)
    }

    public func apply(modelUpdates: ModelUpdate) throws(StateError) -> InstanceKey? {
        let model = modelUpdates.model
        guard let type = modelMap(model) else {
            throw StateError.unknownModel(id: model)
        }
        // TODO: Prevent incomplete updates by running it in an EditingContext
        for update in modelUpdates.updates {
            let instance = database.getOrCreate(id: update.instance, of: type)
            let executor = InstanceUpdateExecutor(
                model: model,
                instance: update.instance,
                properties: update.properties,
                decoder: decoder,
                database: database)
            try instance.apply(update: executor)
        }
        return modelUpdates.hasMoreUpdatesAtInstance
    }

    // MARK: Single instance updates

    public func instanceUpdateRequest(for instance: InstanceKey, of model: ModelKey, after timestamp: Date?) -> InstanceUpdateRequest {
        .init(instance: instance, model: model, timestamp: timestamp)
    }

    /**
     Apply updates received from a remote.
     - Parameter update: The received update.
     - Throws: `StateError`, if the updates could not be applied
     */
    public func apply(instanceUpdate update: InstanceUpdate) throws(StateError) {
        guard let type = modelMap(update.model) else {
            throw StateError.unknownModel(id: update.model)
        }
        guard let instance = database.get(id: update.instance, of: type) else {
            throw StateError.missingInstance(id: update.instance)
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

    // MARK: Commanding

    public func encode(command: CommandBuilder) throws(StateError) -> CommandRequest {
        try command.command(using: encoder)
    }
}
