# class Map extends Object

`Map` is a case-sensitive and type-sensitive associative array. Due to technical limitations, `myMap.Item[key]` must be used rather than `myMap[key]` to ensure that properties and content never mix.

Where `m` is an instance of `Map`:

```
m.Clear()
```
Removes all key-value pairs from the map.

```
m.Count
```
Returns the number of key-value pairs within the map.

```
m.Delete(key)
```
Removes the key and any associated value from the map, and returns the value or an empty string.

```
m.Has(key)
```
Returns true if the map contains this key.

```
m.Item[key]
```
Returns or sets the value associated with `key`.

```
m.__forin()
```
Returns an enumerator function which retrieves key-value pairs. This is normally not called directly, but invoked via `for key, value in m`.