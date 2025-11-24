
/**
 An error produced by state model operations.
 */
public enum StateError: Error {

    /**
     A command could not be executed because no command with the given id is known.
     */
    case unknownCommand(id: PropertyKey)

    /**
     A command execution is missing data for an argument.
     */
    case missingArgument(id: PropertyKey)

    /**
     The data of a command argument could not be decoded during execution
     */
    case argumentDecodingFailed(property: PropertyKey, error: String)

    /**
     A property update could not be decoded while applying instance updates.
     */
    case propertyDecodingFailed(property: PropertyKey, error: String)

    /**
     An error due to a missing instance.

     There are multiple possible causes:
     - A command execution failed because there is no id with this instance
     - Update where requested for a missing instance
     - An update could not be applied since there was no instance with the id.
     */
    case missingInstance(id: InstanceKey)

    /**
     A command argument could not be encoded.
     */
    case argumentEncodingFailed(id: PropertyKey, error: String)

    /**
     The id of a model is not known to a `StateClient`, e.g. the conversion function provided in the init returned `nil`
     */
    case unknownModel(id: ModelKey)

    /**
     Binary data was provided to a `StateClient` that does not match the expected type.

     This error occurs if the client functions are called with binary data from the wrong source,
     e.g. calling `apply(instanceUpdates:)` using data from `updates(for:of:after:)`
     */
    case invalidDataSupplied

    /**
     An update from a `StateClient` could not be converted to binary data.
     */
    case encodingFailed(error: String)

    /**
     Data provided to a `StateClient` could not be decoded.
     */
    case decodingFailed(error: String)

    case success
}

extension StateError: Codable {

}
