/*
 This source file is part of the Swift.org open source project
 Copyright (c) 2020 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

import TSCBasic

/// Thread-safe dictionary like structure
public final class ThreadSafeKeyValueStore<Key, Value> where Key: Hashable {
    private var underlying: [Key: Value]
    private let lock = Lock()

    public init(_ seed: [Key: Value] = [:]) {
        self.underlying = seed
    }

    public subscript(key: Key) -> Value? {
        get {
            self.lock.withLock {
                self.underlying[key]
            }
        } set {
            self.lock.withLock {
                self.underlying[key] = newValue
            }
        }
    }

    @discardableResult
    public func memoize(_ key: Key, body: () throws -> Value) rethrows -> Value {
        try self.lock.withLock {
            try self.underlying.memoize(key: key, body: body)
        }
    }

    public func clear() {
        self.lock.withLock {
            self.underlying.removeAll()
        }
    }

    public var count: Int {
        self.lock.withLock {
            self.underlying.count
        }
    }

    public var isEmpty: Bool {
        self.lock.withLock {
            self.underlying.isEmpty
        }
    }

    public func contains(_ key: Key) -> Bool {
        self.lock.withLock {
            self.underlying.keys.contains(key)
        }
    }

    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key : T] {
        try self.lock.withLock {
            try self.underlying.mapValues(transform)
        }
    }
}

/// Thread-safe value boxing  structure
public final class ThreadSafeBox<Value> {
    private var underlying: Value?
    private let lock = Lock()

    public init() {}

    public init(_ seed: Value) {
        self.underlying = seed
    }

    @discardableResult
    public func memoize(body: () throws -> Value) rethrows -> Value {
        if let value = self.get() {
            return value
        }
        let value = try body()
        self.lock.withLock {
            self.underlying = value
        }
        return value
    }

    public func clear() {
        self.lock.withLock {
            self.underlying = nil
        }
    }

    public func get() -> Value? {
        self.lock.withLock {
            self.underlying
        }
    }

    public func put(_ newValue: Value) {
        self.lock.withLock {
            self.underlying = newValue
        }
    }
}

// FIXME: mark as deprecated once async/await is available
//@available(*, deprecated, message: "replace with async/await when available")
@inlinable
public func temp_await<T, ErrorType>(_ body: (@escaping (Result<T, ErrorType>) -> Void) -> Void) throws -> T {
    return try tsc_await(body)
}
