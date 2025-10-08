
/**
 A sequence that provides an initializer from another sequence.

 Compliance to this protocol is required for types using with the `@ReferenceList` property wrapper in state models.
 */
public protocol SequenceInitializable: Collection {

    init<S: Sequence>(_ sequence: S) where S.Element == Element

    init()
}

extension Array: SequenceInitializable {}

extension ContiguousArray: SequenceInitializable {}

extension Set: SequenceInitializable {}
