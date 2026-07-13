
#if canImport(Combine)

import Combine

/**
 Reexported from `Combine` so that users only have to import `StateModel`, not `Combine` when using the `@Model` macro.
 */
public typealias Publisher = Combine.ObservableObjectPublisher

#else

import OpenCombine

/**
 Reexported from `Combine` so that users only have to import `StateModel`, not `Combine` when using the `@Model` macro.
 */
public typealias Publisher = OpenCombine.ObservableObjectPublisher

#endif

public func createPublisher() -> Publisher {
    .init()
}
