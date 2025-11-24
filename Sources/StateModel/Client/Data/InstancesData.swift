import Foundation

/**
 The encoded data of status updates to instances.

 This data is produced by ``StateClient.instanceStatusUpdates(for:after:)`` and consumed by ``StateClient.apply(instanceUpdates:)``
 */
public typealias InstancesData = Data
