
struct StateModelError: Error {

    let description: String

    init(_ description: String) {
        self.description = description
    }

}

extension StateModelError: CustomStringConvertible {
    
}
