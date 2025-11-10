import Foundation

/**
 The encoded data of a command.

 This data is produced by `StateClient.encode(command:)` and consumed `StateClient.run(command:)`
 */
public typealias CommandData = Data
