import Testing
import StateModel

@Model(id: ModelId.testModel.rawValue)
private final class OptionalModel {

    @Property(id: 1)
    var a: Int?
}

@Model(id: 123)
private final class Nest {

    @Property(id: 1)
    var a: Int
}

@Model(id: 124)
private final class Outer {

    @Reference(id: 1)
    var always: Nest!
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

    @Test("Force unwrapped")
    func forceUnwrappedReference() async throws {
        let database = TestDatabase()
        let instance: Nest = database.create(id: 1)
        let out = Outer.create(in: database, id: 123, always: instance)
        #expect(out.always != nil)
    }
}
