import Foundation

/**
 The encoded data of updates to an instance.

 This data is produced by ``StateClient.updates(for:model:after:)`` and consumed by ``StateClient.apply(instanceUpdate:)``
 */
public typealias InstanceUpdateData = Data
