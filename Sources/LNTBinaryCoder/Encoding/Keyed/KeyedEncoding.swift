//
//  KeyedEncoding.swift
//  
//
//  Created by Natchanon Luangsomboon on 18/2/2563 BE.
//

import Foundation

class TempKeyedStorage: TemporaryEncodingStorage {
    var values: [String: TemporaryEncodingStorage] = [:]

    func finalize() -> EncodingStorage {
        KeyedStorage(values: values.mapValues { $0.finalize() })
    }
}

struct KeyedBinaryEncodingContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
    let storage: TempKeyedStorage, context: EncodingContext

    var codingPath: [CodingKey] { context.codingPath }

    @discardableResult
    private func register<T>(key: CodingKey, value: T) -> T where T: TemporaryEncodingStorage {
        let key = key.stringValue
        context.register(string: key)
        storage.values[key] = value
        return value
    }

    mutating func encodeNil(forKey key: Key) throws {
        register(key: key, value: NilStorage())
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        try value.encode(to: InternalEncoder(storage: register(key: key, value: .init()), context: context.appending(key)))
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        .init(KeyedBinaryEncodingContainer<NestedKey>(storage: register(key: key, value: .init()), context: context.appending(key)))
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        UnkeyedBinaryEncodingContainer(storage: register(key: key, value: .init()), context: context.appending(key))
    }

    mutating func superEncoder() -> Encoder {
        InternalEncoder(storage: register(key: SuperCodingKey(), value: .init()), context: context.appending(SuperCodingKey()))
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        InternalEncoder(storage: register(key: key, value: .init()), context: context.appending(key))
    }
}
