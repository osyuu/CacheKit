# MyCacheKit

A simple cache interface for practicing.

## Usage

```swift
import MyCacheKit

// Cache<Key, Value>
let cache = Cache<String, Data>.init()

// read
let value = cache.value(forKey: "key")

// write
cache.insert(Data(), forKey: "key")

// remove
cache.remove(forKey: "key")

// save to Disk
try cache.saveToDisk(withName: "cache name")
```

## LICENSE

DataMyCacheKit is available under the MIT license, and uses source code from open source projects. See the [LICENSE](https://github.com/osyuu/MyCacheKit/blob/main/LICENSE) file for more info.
