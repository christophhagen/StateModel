
/// Sleep for the given number of milliseconds
func sleep(ms: UInt64) async throws {
    try await Task.sleep(nanoseconds: ms * 1_000_000) // ms
}
