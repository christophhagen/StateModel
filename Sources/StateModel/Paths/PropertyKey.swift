
/// A property key is used to uniquely identify the properties of models in the database.
public typealias PropertyKey = Int

extension PropertyKey {

    /**
     The unique id to use when storing information about the instance of a model,
     e.g. whether an object is deleted or created.

     This property is set to ``zero``

     - Warning: This id must not be used when assigning ids to new instances, otherwise data corruption will occur.

     When an object is created in the database, then the `instanceId` is used to store the state of the instance ( `created`),
     so that all existing elements of the type can be queried.
     */
    public static var instanceId: Self { .zero }
}
