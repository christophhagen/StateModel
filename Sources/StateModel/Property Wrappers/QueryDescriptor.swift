
public struct QueryDescriptor<Result: ModelProtocol> {

    let id: Int

    let isIncluded: ((Result) -> Bool)?

    let areInIncreasingOrder: ((Result, Result) -> Bool)?

    public init(filter isIncluded: ((Result) -> Bool)? = nil,
                sort areInIncreasingOrder: ((Result, Result) -> Bool)? = nil) {
        self.id = .random(in: Int.min...Int.max)
        self.isIncluded = isIncluded
        self.areInIncreasingOrder = areInIncreasingOrder
    }
}

extension QueryDescriptor: Equatable {

    public static func == (lhs: QueryDescriptor<Result>, rhs: QueryDescriptor<Result>) -> Bool {
        lhs.id == rhs.id
    }
}
