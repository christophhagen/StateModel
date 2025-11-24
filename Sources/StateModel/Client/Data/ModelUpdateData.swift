import Foundation

/**
 The encoded data of updates to multiple instances.

 This data is produced by ``StateClient.allUpdates(for:after:limit:startingAt:)`` and consumed by ``StateClient.apply(modelUpdates:)``
 */
public typealias ModelUpdateData = Data
