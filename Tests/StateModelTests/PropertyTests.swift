import Testing
import StateModel

@Suite("Properties")
struct PropertyTests {

    @Test("Set and get value")
    func testProperty() async throws {
        let database = TestDatabase()

        let instanceA: TestModel = database.create(id: 123)
        #expect(instanceA.a == 0)
        #expect(instanceA.b == -1)

        let instanceB: TestModel = database.create(id: 234)
        #expect(instanceB.a == 0)
        #expect(instanceB.b == -1)

        instanceA.a = 12
        instanceA.b = 56
        instanceB.a = 34
        instanceB.b = 67

        #expect(instanceA.a == 12)
        #expect(instanceA.b == 56)
        #expect(instanceB.a == 34)
        #expect(instanceB.b == 67)
    }


    @Test("Modification")
    func propertyModification() {
        let database = TestDatabase()

        let model = database.create(id: 1, of: TestModel.self)

        model.a = 2
        #expect(model.a == 2)
        model.a += 3
        #expect(model.a == 5)

        let model2 = database.create(id: 2, of: TestModel.self)
        #expect(model2.a == 0)
        model2.a = model.a
        #expect(model2.a == 5)
    }

    @Test("Complex default")
    func testComplexDefault() {
        let database = TestDatabase()

        let color =  Color(red: 42, green: 42, blue: 42)

        let model = ComplexModel.create(in: database, id: 123, color: color)
        #expect(model.color == color)
        #expect(model.color != Color.defaultValue)
    }
}

@Model(id: 1)
private class ComplexModel {

    @Property(id: 1)
    var color: Color = .defaultValue
}

private struct Color: Codable, Equatable {

    let red: UInt8
    let green: UInt8
    let blue: UInt8

    static var defaultValue: Color {
        .init(red: 1, green: 2, blue: 3)
    }
}
