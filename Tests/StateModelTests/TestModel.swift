import Foundation
import StateModel

enum ModelId: Int, Comparable, Codable {

    static func < (lhs: ModelId, rhs: ModelId) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case testModel = 1
    case otherModel = 2
    case repeatedModel = 3
}

typealias TestDatabase = InMemoryDatabase

struct MyPrimitive: Codable, Defaultable {

    var value: Int

    static let `default` = MyPrimitive(value: 0)
}

@Model(id: ModelId.testModel.rawValue)
final class TestModel {

    @Property(id: 1)
    var a: Int

    @Property(id: 2)
    var b: Int = -1

    @Reference(id: 3)
    var ref: NestedModel?

    @ReferenceList(id: 4)
    var list: [NestedModel]

    @Property(id: 5)
    var c: MyPrimitive

    let fixed = 1

    var sum: Int {
        a + b
    }
}

@Model(id: ModelId.otherModel.rawValue)
final class NestedModel {

    @Property(id: 1)
    var some: Int
}

@Model(id: ModelId.repeatedModel.rawValue)
final class RepeatedModel {

    @Property(id: 1)
    var some: Int
}
