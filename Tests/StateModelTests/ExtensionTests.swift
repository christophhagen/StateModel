@testable import StateModel
import Testing

@Suite("Extensions")
struct ExtensionTests {
    
    @Test("Move in sorted array")
    func moveInSortedArray() {
        let expected = [1,2,3,4,5,6,7,8,9]

        do {
            var modified = [1,2,3,4,5,7,6,8,9]
            modified.resortElement(at: 5, by: { $0 < $1 })
            #expect(modified == expected)
        }
        do {
            var modified = [7,1,2,3,4,5,6,8,9]
            modified.resortElement(at: 0, by: { $0 < $1 })
            #expect(modified == expected)
        }

        do {
            var modified = [1,2,3,4,5,6,8,7,9]
            modified.resortElement(at: 7, by: { $0 < $1 })
            #expect(modified == expected)
        }
    }
}
