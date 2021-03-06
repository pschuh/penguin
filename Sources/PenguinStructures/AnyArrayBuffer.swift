// Copyright 2020 Penguin Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// A resizable, value-semantic buffer of homogenous elements of
/// statically-unknown type.
public struct AnyArrayBuffer<Storage: AnyArrayStorage> {
  /// A bounded contiguous buffer comprising all of `self`'s storage.
  internal var storage: Storage
  
  init(storage: Storage) { self.storage = storage }
  
  public init<SrcStorage>(_ src: ArrayBuffer<SrcStorage>) {
    // The downcast would be unnecessary but for
    // https://bugs.swift.org/browse/SR-12906
    self.storage = unsafeDowncast(src.storage, to: Storage.self)
  }

  /// The type of element stored here.
  public var elementType: Any.Type { storage.elementType }
}

extension AnyArrayBuffer {
  /// The number of stored elements.
  public var count: Int { storage.count }

  /// The number of elements that can be stored in `self` without reallocation,
  /// provided its representation is not shared with other instances.
  public var capacity: Int { storage.capacity }

  /// Appends `x`, returning the index of the appended element.
  ///
  /// - Complexity: Amortized O(1).
  /// - Precondition: `type(of: x) == elementType`
  public mutating func append<T>(_ x: T) -> Int {
    assert(type(of: x) == elementType)
    let isUnique = isKnownUniquelyReferenced(&storage)
    return withUnsafePointer(to: x) {
      if isUnique, let r = storage.appendValue(at: .init($0)) { return r }
      storage = storage.appendingValue(at: .init($0), moveElements: isUnique)
      return count - 1
    }
  }
}
