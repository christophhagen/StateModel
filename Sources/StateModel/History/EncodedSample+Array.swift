import Foundation

extension Array where Element == EncodedSample {

    mutating func insert(_ sample: EncodedSample) {
        // Find the sample index bigger than the date
        let index = lastIndex { $0.timestamp > sample.timestamp } ?? count
        insert(sample, at: index)
    }

    func contains(_ date: Date) -> Bool {
        contains { $0.timestamp == date }
    }

    func at(_ date: Date?) -> EncodedSample? {
        guard let date else {
            return last
        }
        // Find the sample index bigger than the date
        let lastIndex = lastIndex { $0.timestamp > date } ?? count
        guard lastIndex > 0 else {
            return nil
        }
        return self[lastIndex - 1]
    }
}
