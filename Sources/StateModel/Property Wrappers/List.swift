
/**
 An array that lazy loads the contained objects from the database.

 The objects are internally stored as references using their instance id,
 and a model is only queried from the database when the array element is accessed.

 `List` is used with `ReferenceList` to manage repeated references to other models:

 ```swift
 class MyModel: Model<MyDatabase> {
     static let modelId = 1

     @ReferenceList(id: 1)
     var list: List<Nested>
 }
 ```
 */
public struct List<Value>: RangeReplaceableCollection, RandomAccessCollection where Value: ModelProtocol {

    /// The reference to the database from which the objects are queried.
    unowned let database: Value.Storage

    /// The instance ids of the objects in the list
    private(set) var references: [Value.InstanceKey]

    /**
     Create a list.
     - Parameter database: The reference to the database
     - Parameter references: The instance ids of the objects in the list
     */
    init(database: Value.Storage, references: [Value.InstanceKey] = []) {
        self.database = database
        self.references = references
    }

    /**
     The position of the first element in a nonempty array.

     For an instance of `List`, `startIndex` is always `zero`.
     If the array is empty, `startIndex` is equal to `endIndex`.
     */
    public var startIndex: Int { references.startIndex }

    /// The array's "past the end" position---that is, the position one greater
    /// than the last valid subscript argument.
    ///
    /// When you need a range that includes the last element of an array, use the
    /// half-open range operator (`..<`) with `endIndex`. The `..<` operator
    /// creates a range that doesn't include the upper bound, so it's always
    /// safe to use with `endIndex`. For example:
    ///
    ///     let numbers = [10, 20, 30, 40, 50]
    ///     if let i = numbers.firstIndex(of: 30) {
    ///         print(numbers[i ..< numbers.endIndex])
    ///     }
    ///     // Prints "[30, 40, 50]"
    ///
    /// If the array is empty, `endIndex` is equal to `startIndex`.
    public var endIndex: Int { references.endIndex }

    /// Accesses the referenced object at the specified position.
    ///
    /// - Parameter index: The position of the object to access. `index` must be
    ///   greater than or equal to `startIndex` and less than `endIndex`.
    ///
    /// - Complexity: Reading an element from an list is O(1), but includes a query for the object in the database.
    /// - Note: If a referenced object is accessed, then it is automatically created in the database if it does not exist. Deleted instances are returned unchanged.
    public subscript(index: Int) -> Value {
        let reference = self.references[index]
        return database.getOrCreate(id: reference)
    }

    // MARK: - Mutation

    /// Inserts a new element at the specified position.
    ///
    /// The new element is inserted before the element currently at the specified
    /// index. If you pass the array's `endIndex` property as the `index`
    /// parameter, the new element is appended to the array.
    ///
    ///     var numbers = [1, 2, 3, 4, 5]
    ///     numbers.insert(100, at: 3)
    ///     numbers.insert(200, at: numbers.endIndex)
    ///
    ///     print(numbers)
    ///     // Prints "[1, 2, 3, 100, 4, 5, 200]"
    ///
    /// - Parameter newElement: The new element to insert into the array.
    /// - Parameter i: The position at which to insert the new element.
    ///   `index` must be a valid index of the array or equal to its `endIndex`
    ///   property.
    ///
    public mutating func insert(_ value: Value, at index: Int) {
        references.insert(value.id, at: index)
    }

    /// Adds a new element at the end of the array.
    ///
    /// Use this method to append a single element to the end of a mutable array.
    /// - Parameter newElement: The element to append to the array.
    public mutating func append(_ value: Value) {
        references.append(value.id)
    }

    /**
     - Warning: This initializer will produce a `fatalError`, since the `List` requires a database reference to operate.
     */
    public init() {
        fatalError("Use init(database:references:) instead.")
    }

    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index immediately after `i`.
    public func index(after i: Int) -> Int {
        references.index(after: i)
    }

    /// Replaces a range of elements with the elements in the specified
    /// collection.
    ///
    /// This method has the effect of removing the specified range of elements
    /// from the array and inserting the new elements at the same location. The
    /// number of new elements need not match the number of elements being
    /// removed.
    ///
    /// - Parameters:
    ///   - subrange: The subrange of the array to replace. The start and end of
    ///     a subrange must be valid indices of the array.
    ///   - newElements: The new elements to add to the array.
    /// - Note: The status of the inserted and replaced elements will not be changed.
    public mutating func replaceSubrange<C: Collection>(_ subrange: Range<Int>, with newElements: C) where C.Element == Value {
        let newKeys = newElements.map { $0.id }
        references.replaceSubrange(subrange, with: newKeys)
    }

    /// Removes and returns the element at the specified position.
    ///
    /// - Parameter index: The position of the element to remove. `index` must
    ///   be a valid index of the array.
    /// - Note: The status of the removed element is not changed.
    public mutating func remove(at index: Int) {
        references.remove(at: index)
    }

    /// Removes all the elements that satisfy the given predicate.
    ///
    /// Use this method to remove every element in a collection that meets
    /// particular criteria. The order of the remaining elements is preserved.
    /// - Parameter shouldBeRemoved: A closure that takes an element of the
    ///   sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be removed from the collection.
    /// - Note: The status of the removed elements is not changed. Instances that do not exist in the database will be created when accessed.
    public mutating func removeAll(where shouldBeRemoved: (Value) -> Bool) {
        var old = references
        old.removeAll { key in
            let value: Value = database.getOrCreate(id: key)
            return shouldBeRemoved(value)
        }
        self.references = old
    }
}

extension List: ExpressibleByArrayLiteral {

    /**
     Create a list using an array literal.
     - Note: A `fatalError` will be thrown for an empty array literal, since the first element will supply the reference to the database.
     */
    public init(arrayLiteral elements: Value...) {
        guard let db = elements.first?.database else {
            fatalError("Can't create an empty List without a database")
        }
        self.init(database: db, references: elements.map(\.id))
    }
}
