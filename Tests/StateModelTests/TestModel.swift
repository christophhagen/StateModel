import Foundation
import StateModel

enum ModelId: Int {
    case testModel = 1
    case otherModel = 2
    case repeatedModel = 3
}

typealias TestDatabase = InMemoryDatabase<Int, Int, Int>
typealias TestBaseModel = Model<TestDatabase>

final class TestModel: TestBaseModel {

    static let modelId = ModelId.testModel.rawValue

    @Property(id: PropertyId.a)
    var a: Int

    @Property(id: PropertyId.b, default: -1)
    var b: Int

    @Reference(id: PropertyId.ref)
    var ref: NestedModel?

    @ReferenceList(id: PropertyId.list)
    var list: List<NestedModel>

    enum PropertyId: Int {
        case a = 1
        case b = 2
        case ref = 3
        case list = 4
    }
}

final class NestedModel: TestBaseModel {

    static let modelId = ModelId.otherModel.rawValue

    @Property(id: 1)
    var some: Int
}


final class RepeatedModel: TestBaseModel {

    static let modelId = ModelId.repeatedModel.rawValue

    @Property(id: 1)
    var some: Int
}
