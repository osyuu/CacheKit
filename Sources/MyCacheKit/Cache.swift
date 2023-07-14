//
//  Cache.swift
//  
//
//  Created by Jhou WJ on 2023/7/13.
//

import Foundation

public final class Cache<Key: Hashable, Value: Codable> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date
    private let entryLifetime: TimeInterval
    private let keyTracker = KeyTracker()
    
    public init(dateProvider: @escaping () -> Date = Date.init, entryLifetime: TimeInterval = 12 * 60 * 60, maximumEntryCount: Int = 50) {
        self.dateProvider = dateProvider
        self.entryLifetime = entryLifetime
        wrapped.countLimit = maximumEntryCount
        wrapped.delegate = keyTracker
    }
    
    public func insert(_ value: Value, forKey key: Key) {
        let date = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(key: key, value: value, expirationDate: date)
        let wrappedKey = WrappedKey(key)
        wrapped.setObject(entry, forKey: wrappedKey)
        keyTracker.keys.insert(key)
    }
    
    public func value(forKey key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }
        
        guard dateProvider() < entry.expirationDate else {
            remove(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    public func remove(forKey key: Key) {
        let wrappedKey = WrappedKey(key)
        wrapped.removeObject(forKey: wrappedKey)
    }
}

private extension Cache {
    final class WrappedKey: NSObject {
        let key: Key
        
        init(_ key: Key) { self.key = key }
        
        override var hash: Int { return key.hashValue }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }
            return value.key == key
        }
    }
}

private extension Cache {
    final class Entry {
        let key: Key
        let value: Value
        let expirationDate: Date

        init(key: Key, value: Value, expirationDate: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

private extension Cache {
    final class KeyTracker: NSObject, NSCacheDelegate {
        var keys = Set<Key>()
        
        func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
            guard let entry = obj as? Entry else { return }
            
            keys.remove(entry.key)
        }
    }
}

extension Cache {
    public subscript(key: Key) -> Value? {
        get {
            return value(forKey: key)
        }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                remove(forKey: key)
                return
            }
            insert(value, forKey: key)
        }
    }
}

extension Cache.Entry: Codable where Key: Codable, Value: Codable {}

private extension Cache {
    func entry(forKey key: Key) -> Entry? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }

        guard dateProvider() < entry.expirationDate else {
            remove(forKey: key)
            return nil
        }

        return entry
    }

    func insert(_ entry: Entry) {
        wrapped.setObject(entry, forKey: WrappedKey(entry.key))
        keyTracker.keys.insert(entry.key)
    }
}

extension Cache: Codable where Key: Codable, Value: Codable {
    convenience public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyTracker.keys.compactMap(entry))
    }
    
    public func saveToDisk(
        withName name: String,
        using fileManager: FileManager = .default
    ) throws {
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL)
    }
}
