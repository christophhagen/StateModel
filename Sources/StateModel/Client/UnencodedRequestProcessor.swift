import Foundation

/**
 A provider to process requests from clients.

 Use this provider if client and provider are accessible from the same code,
 i.e. if no data transmission is needed.
 - SeeAlso: ``RequestProcessor``
 */
public struct UnencodedRequestProcessor {

    /// The database to use when processing requests
    public let database: Database

    /// A mapping of all model ids to their associated types
    private let modelMap: (ModelKey) -> (any ModelProtocol.Type)?

    /// The encoder used to encode property values
    private let encoder: any GenericEncoder

    /// The decoder used to decode command arguments
    private let decoder: any GenericDecoder

    /**
     - Parameter database: The database to use when processing requests
     - Parameter encoder: The encoder used to encode property values
     - Parameter decoder: The decoder used to decode command arguments
     - Parameter modelMap: A mapping of all model ids to their associated types
     */
    public init(
        database: Database,
        encoder: any GenericEncoder,
        decoder: any GenericDecoder,
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
     - Parameter request: The request
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: An update object containing all updates.
     - Throws: `StateError.unknownModelId` if the model id is unknown
     */
    public func instanceStatusUpdates(for request: InstanceStatusRequest) -> InstancesUpdate {
        instanceStatusUpdates(for: request.model, after: request.timestamp)
    }

    /**
     Retrieve all updates to instances of a specific model.
     - Parameter model: The type of the instances to query.
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: An update object containing all updates.
     - Throws: `StateError.unknownModelId` if the model id is unknown
     */
    public func instanceStatusUpdates<T: ModelProtocol>(for model: T.Type, after timestamp: Date?) -> InstancesUpdate {
         instanceStatusUpdates(for: T.modelId, after: timestamp)
    }

    /**
     Retrieve all updates to instances of a specific model.
     - Parameter model: The model id of the instances to get
     - Parameter timestamp: The date after which the updates should be considered.
     - Returns: An update object containing all updates.
     - Throws: `StateError.unknownModelId` if the model id is unknown
     */
    public func instanceStatusUpdates(for model: ModelKey, after timestamp: Date?) -> InstancesUpdate {
        guard modelMap(model) != nil else {
            // If the model id is unknown, then there are no updates
            return .init(model: model, updates: [])
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

    public func allUpdates(for request: ModelUpdateRequest) -> ModelUpdate {
        allUpdates(for: request.model, after: request.timestamp, limit: request.limit, startingAt: request.instance)
    }

    public func allUpdates<T: ModelProtocol>(for model: T.Type, after timestamp: Date?, limit: Int, startingAt instance: Int? = nil) -> ModelUpdate {
        allUpdates(for: T.modelId, after: timestamp, limit: limit, startingAt: instance)
    }

    /**
     Retrieve changed properties for instances of a model.
     - Parameter model: The id of the model
     - Parameter timestamp: The earliest date for which changes should be considered.
     - Parameter limit: The maximum number of updates to include.
     - Parameter instance: The lowest instance id to consider
     */
    public func allUpdates(for model: ModelKey, after timestamp: Date?, limit: Int, startingAt instance: Int? = nil) -> ModelUpdate {
        guard let type = modelMap(model) else {
            // If model is unknown, then no updates exist
            return .init(model: model, updates: [], hasMoreUpdatesAtInstance: nil)
        }

        let instanceIds = getInstanceIds(of: model, startingAt: instance).sorted()

        var numberOfUpdates = 0
        var updates: [ModelInstanceUpdate] = []
        for instance in instanceIds {
            let update = uncheckedUpdates(for: instance, of: type, after: timestamp)
            let updateCount = update.properties.count
            guard updateCount > 0 else { continue }
            numberOfUpdates += updateCount
            guard numberOfUpdates <= limit else {
                return .init(model: model, updates: updates, hasMoreUpdatesAtInstance: instance)
            }
            updates.append(.init(instance: instance, properties: update.properties))
        }
        return .init(model: model, updates: updates, hasMoreUpdatesAtInstance: nil)
    }

    private func getInstanceIds(of model: ModelKey, startingAt instance: Int?) -> [InstanceKey] {
        guard let instance else {
            return database.all(model: model) { id, _ in id }
        }

        // Filter out all instances before the start
        return database.all(model: model) { id, _ in
            id < instance ? nil : id
        }
    }
    
    // MARK: Single instance updates

    public func instanceUpdateRequest(for instance: InstanceKey, of model: ModelKey, after timestamp: Date?) -> InstanceUpdateRequest {
        .init(instance: instance, model: model, timestamp: timestamp)
    }

    public func process(instanceUpdateRequest request: InstanceUpdateRequest) -> InstanceUpdate {
        updates(for: request.instance, of: request.model, after: request.timestamp)
    }

    /**
     Get updates to the properties of a specific instance.
     - Parameter instance: The unique id of the instance
     - Parameter model: The type of the instance to update.
     - Parameter timestamp: The earliest date to consider for updates. Set to `nil` to get the full current state.
     - Returns: An update object containing all requested updates
     */
    public func updates<T: ModelProtocol>(for instance: InstanceKey, of model: T.Type, after timestamp: Date?) -> InstanceUpdate {
        updates(for: instance, of: T.modelId, after: timestamp)
    }

    /**
     Get updates to the properties of a specific instance.
     - Parameter instance: The unique id of the instance
     - Parameter model: The model id of the instance to update.
     - Parameter timestamp: The earliest date to consider for updates. Set to `nil` to get the full current state.
     - Returns: An update object containing all requested updates
     - Throws: `CommandError`, if the model is unknown, if there is no matching instance, or if the property data could not be encoded.
     */
    public func updates(for instance: InstanceKey, of model: ModelKey, after timestamp: Date?) -> InstanceUpdate {
        guard let type = modelMap(model) else {
            // No updates for unknown models
            return .init(model: model, instance: instance)
        }
        guard database.get(id: instance, of: type) != nil else {
            // No updates, if instance does not exist
            return .init(model: model, instance: instance)
        }
        return uncheckedUpdates(for: instance, of: type, after: timestamp)
    }

    /**
     Get all updated properties for an instance, without checking if the instance exists.

     The properties are encoded using the encoder provided to the request processor.
     */
    private func uncheckedUpdates(for instance: InstanceKey, of model: any ModelProtocol.Type, after timestamp: Date?) -> InstanceUpdate {
        let builder = InstanceUpdateBuilder(
            model: model.modelId,
            instance: instance,
            time: timestamp,
            database: database,
            encoder: encoder)

        // Set the builder as the database, so that it can record all property accesses,
        // and store them in the update.
        let instance = model.init(database: builder, id: instance)
        instance.accessAllPropertiesForUpdateCalculation()
        return builder.update()
    }

    // MARK: Instance commanding

    /**
     Run a command received from a remote on the local database.
     - Parameter command: The command to execute
     - Returns: A `StateError`, if the command failed to execute.
     */
    public func process(command: CommandRequest) -> StateError {
        let executor = EncodedCommandExecutor(command: command, decoder: decoder)
        guard let type = modelMap(executor.model) else {
            return StateError.unknownModel(id: executor.model)
        }
        guard let instance = database.get(id: executor.instance, of: type) else {
            return StateError.missingInstance(id: executor.instance)
        }
        do {
            try instance.execute(command: executor)
            return .success
        } catch let error {
            return error
        }
    }
}
