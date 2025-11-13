import Foundation
import Testing
import StateModel

@Suite("Encoding")
struct EncodingTests {

    @Test("Path")
    func testEncodePath() throws {
        let path = Path(model: 123, instance: 234, property: 345)

        let data = try JSONEncoder().encode(path)
        let decoded = try JSONDecoder().decode(Path.self, from: data)
        #expect(decoded == path)
    }

    @Test("StateCommand")
    func testStateCommand() throws {
        let path = Path(model: 123, instance: 234, property: 345)
        let arguments: [PropertyKey : Data] = [
            2 : Data(repeating: 42, count: 12),
            173 : Data(repeating: 7, count: 13)
        ]
        let command = StateCommand(path: path, arguments: arguments)

        let data = try JSONEncoder().encode(command)
        let decoded = try JSONDecoder().decode(StateCommand.self, from: data)
        #expect(command == decoded)
    }

    @Test("PropertyChange")
    func testPropertyChange() throws {
        let change = PropertyChange(id: 123, date: Date(), data: .init(repeating: 42, count: 13))

        let data = try JSONEncoder().encode(change)
        let decoded = try JSONDecoder().decode(PropertyChange.self, from: data)
        #expect(decoded.id == change.id)
        #expect(abs(decoded.date.timeIntervalSince(change.date)) < 0.00001)
        #expect(decoded.data == change.data)
    }
}
