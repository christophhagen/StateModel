import Testing
#if canImport(Combine)
import Combine
#else
import OpenCombine
#endif

/// Sleep for the given number of milliseconds
func sleep(ms: UInt64) async throws {
    try await Task.sleep(nanoseconds: ms * 1_000_000) // ms
}


func observeChange<O: ObservableObject>(
    to object: O,
    _ message: String? = nil,
    trigger: () throws -> Void
) async rethrows {
    var cancellables: Set<AnyCancellable> = []
    let comment = message.map { Comment.init(stringLiteral: $0) }
    try await confirmation(comment) { confirm in
        // Subscribe before triggering
        object.objectWillChange
            .sink { _ in confirm() }
            .store(in: &cancellables)

        try trigger()
    }
}
