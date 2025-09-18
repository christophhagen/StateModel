import Testing
import StateModel

@Suite("Transfer")
struct TransferTests {

    @Test("Export and import")
    func testTransferHistory() {
        let database1 = TestDatabase()

        let model1: TestModel = database1.create(id: 123)
        let nested1: NestedModel = database1.create(id: 234)
        model1.a = 123
        model1.b = 234
        model1.ref = nested1
        model1.list.append(nested1)
        nested1.some = 42

        let history = database1.getEncodedHistory()

        let database2 = TestDatabase()
        let inserted = database2.insert(records: history)
        #expect(inserted)

        let model2: TestModel! = database2.get(id: 123)
        #expect(model2 != nil)
        #expect(model2.a == 123)
        #expect(model2.b == 234)
        let nested2: NestedModel! = model2.ref
        #expect(nested2 != nil)
        #expect(model2.list.count == 1)
        #expect(model2.list[0] == nested2)
        #expect(nested2 == nested1)
        #expect(nested2.some == 42)
    }
}
