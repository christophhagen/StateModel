

extension AdditiveArithmetic {

    /**
     The unique id to use when storing information about the instance of a model,
     e.g. whether an object is deleted or created.

     This property is required for conformance with ``PropertyKeyType``, and is set to ``zero``

     - Warning: This id must not be used when assigning ids to new instances, otherwise data corruption will occur.

     When an object is created in the database, then the `instanceId` is used to store the state of the instance ( `created`),
     so that all existing elements of the type can be queried.
     */
    public static var instanceId: Self { .zero }
}

extension Int: PropertyKeyType { }
extension Int8: PropertyKeyType { }
extension Int16: PropertyKeyType { }
extension Int32: PropertyKeyType { }
extension Int64: PropertyKeyType { }

extension UInt: PropertyKeyType { }
extension UInt8: PropertyKeyType { }
extension UInt16: PropertyKeyType { }
extension UInt32: PropertyKeyType { }
extension UInt64: PropertyKeyType { }
