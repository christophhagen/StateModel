#if canImport(Combine)
import Combine

/**
 Reexported from `Combine` so that users only have to import `StateModel`, not `Combine` when using the `@Model` macro.
 */
public typealias ObservableObject = Combine.ObservableObject

#else
import OpenCombine

/**
 Reexported from `Combine` so that users only have to import `StateModel`, not `Combine` when using the `@Model` macro.
 */
public typealias ObservableObject = OpenCombine.ObservableObject
#endif
