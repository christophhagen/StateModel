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

@Model(id: ModelId.testModel.rawValue)
final class TestModel {

    @Property(id: PropertyId.a)
    var a: Int

    @Property(id: PropertyId.b, default: -1)
    var b: Int

    @Reference(id: PropertyId.ref)
    var ref: NestedModel?

    @ReferenceList(id: PropertyId.list)
    var list: [NestedModel]

    enum PropertyId: Int {
        case a = 1
        case b = 2
        case ref = 3
        case list = 4
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
