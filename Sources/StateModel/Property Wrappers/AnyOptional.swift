
public protocol AnyOptional {

    static var nilValue: Self { get }
}

extension Optional: AnyOptional {

    public static var nilValue: Optional<Wrapped> { .none }
}
