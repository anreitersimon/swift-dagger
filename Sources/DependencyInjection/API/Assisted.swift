@propertyWrapper
public struct Assisted<V> {
    public var wrappedValue: V

    public init(wrappedValue: V, _ name: StaticString? = nil) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper
public struct Inject<V> {
    public var wrappedValue: V

    public init(wrappedValue: V, _ name: StaticString? = nil) {
        self.wrappedValue = wrappedValue
    }
}