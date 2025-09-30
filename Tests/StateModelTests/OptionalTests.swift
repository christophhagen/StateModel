import Testing
import StateModel

private final class OptionalModel: TestBaseModel {

    static let modelId = ModelId.testModel.rawValue

    @Property(id: 1)
    var a: Int?
}

@Suite("Optionals")
struct OptionalTests {

    @Test("Optional property")
    func optionalProperty() async throws {
        let database = TestDatabase()
        let instance: OptionalModel = database.create(id: 123)
        #expect(instance.a == nil)
        instance.a = 42
        #expect(instance.a == 42)
    }
}
