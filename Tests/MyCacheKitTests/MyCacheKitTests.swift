import XCTest
@testable import MyCacheKit

final class MyCacheKitTests: XCTestCase {
        
    func testInsertData() throws {
        
        let cache = Cache<String, Data>.init()
        
        cache.insert(Data(), forKey: "empty")
        
        let data = cache["empty"]
        XCTAssertEqual(data, Data())
    }
    
    func testInsertDataMultiple() throws {
        let cache = Cache<String, Data>.init()

        cache.insert(Data([1]), forKey: "empty0")
        cache.insert(Data([1, 2]), forKey: "empty1")
        
        let data = cache["empty0"]
        XCTAssertEqual(data, Data([1]))
        let data1 = cache["empty1"]
        XCTAssertEqual(data1, Data([1, 2]))
    }
    
    func testRemoveData() throws {
        let cache = Cache<String, Data>.init()
        
        cache.insert(Data(), forKey: "empty0")
        cache.insert(Data([1, 2]), forKey: "empty1")
        
        cache.remove(forKey: "empty0")
        
        let data0 = cache["empty0"]
        let data1 = cache["empty1"]
        XCTAssertNil(data0)
        XCTAssertEqual(data1, Data([1, 2]))
    }
    
    func testInsertDiskData() throws {
        let name = "test"
        let cache = Cache<String, Data>.init()
        cache.insert(Data([1]), forKey: "empty0")
        cache.insert(Data([1, 2]), forKey: "empty1")
        
        try cache.saveToDisk(withName: name)
        
        let folderURLs = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        

        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let cache1 = try decoder.decode(Cache<String, Data>.self, from: data)
        
        let data0 = cache1["empty0"]
        let data1 = cache1["empty1"]
        XCTAssertEqual(data0, Data([1]))
        XCTAssertEqual(data1, Data([1, 2]))
    }
    
    func testInsertDiskDataMultiple() throws {
        let name = "test"
        let cache = Cache<String, Data>.init()
        cache.insert(Data([1]), forKey: "empty0")
        
        let name1 = "test1"
        let cache1 = Cache<String, Data>.init()
        cache1.insert(Data([1, 2]), forKey: "empty0")
        
        try cache.saveToDisk(withName: name)
        try cache1.saveToDisk(withName: name1)
        
        let folderURLs = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        
        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let fileURL1 = folderURLs[0].appendingPathComponent(name1 + ".cache")

        let data = try Data(contentsOf: fileURL)
        let data1 = try Data(contentsOf: fileURL1)
        let decoder = JSONDecoder()
        let cacheLoader = try decoder.decode(Cache<String, Data>.self, from: data)
        let cache1Loader = try decoder.decode(Cache<String, Data>.self, from: data1)
        
        let dataLoader0 = cacheLoader["empty0"]
        let dataLoader1 = cache1Loader["empty0"]
        XCTAssertEqual(dataLoader0, Data([1]))
        XCTAssertEqual(dataLoader1, Data([1, 2]))
    }
    
    func testDiskDataEntryLifetime() async throws {
        let name = "test"
        let cache = Cache<String, Data>.init(entryLifetime: 3)
        cache.insert(Data([1]), forKey: "empty0")
        
        try cache.saveToDisk(withName: name)
        
        do {
            sleep(5)
        }
        
        let folderURLs = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        
        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let cacheLoader = try decoder.decode(Cache<String, Data>.self, from: data)
        
        let dataLoader0 = cacheLoader["empty0"]
        XCTAssertNil(dataLoader0)
    }
    
    func testDataLimit() async throws {
        let cache = Cache<String, Data>.init(maximumEntryCount: 2)
        cache.insert(Data([1]), forKey: "empty1")
        cache.insert(Data([1, 2]), forKey: "empty2")
        cache.insert(Data([1, 2, 3]), forKey: "empty3")
        
        let data1 = cache["empty1"]
        let data2 = cache["empty2"]
        let data3 = cache["empty3"]
        XCTAssertNil(data1)
        XCTAssertEqual(data2, Data([1, 2]))
        XCTAssertEqual(data3, Data([1, 2, 3]))
    }
}
