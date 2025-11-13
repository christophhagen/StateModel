
#if canImport(Combine)

import Combine

/**
 Reexported from `Combine` so that users only have to import `StateModel`, not `Combine` when using the `@Model` macro.
 */
public typealias ObservableObjectPublisher = Combine.ObservableObjectPublisher

#else

import OpenCombine

/**
 Reexported from `Combine` so that users only have to import `StateModel`, not `Combine` when using the `@Model` macro.
 */
public typealias ObservableObjectPublisher = OpenCombine.ObservableObjectPublisher

#endif
