import Foundation

/**
 Updated properties and status for multiple instances of a model.
 */
public struct ModelUpdate {

    public let model: ModelKey

    public let updates: [ModelInstanceUpdate]

    /**
     There are more updates available on the server beginning with the given id

     To retrieve additional updates, call `UnencodedStateClient.allUpdates()` again with the instanceId set to 1 larger than the id of the last update.
     */
    public let hasMoreUpdatesAtInstance: InstanceKey?

    init(model: ModelKey,
         updates: [ModelInstanceUpdate],
         hasMoreUpdatesAtInstance: InstanceKey?
    ) {
        self.model = model
        self.updates = updates
        self.hasMoreUpdatesAtInstance = hasMoreUpdatesAtInstance
    }
}

extension ModelUpdate: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(TransmissionDataType.modelUpdates)
        try container.encode(model)
        try container.encode(updates)
        try container.encode(hasMoreUpdatesAtInstance)
    }
}

extension ModelUpdate: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(TransmissionDataType.self) == .modelUpdates else {
            throw StateError.invalidDataSupplied
        }
        self.model = try container.decode()
        self.updates = try container.decode()
        self.hasMoreUpdatesAtInstance = try container.decode()
    }
}
