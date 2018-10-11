# class Array extends Object

A one-based array or linear sequence. An array is expected to have exactly `Length` elements, but each element may or may not have a value set, and memory may or may not be reserved in advance for unset elements.

If `Object.Override.ahk` is used, objects created by `[]` or `Array()` are instances of `Array`.

**Known limitation:** Increasing an array's length by setting its `Length` property will cause the new last element to incorrectly be marked as having a value set.

**Known limitation:** The `vararg*` parameter of a variadic function always receives a plain AutoHotkey object, not an instance of `Array`. One can convert it with the expression `new Array(vararg*)`. If `Object.Override.ahk` is used, one can use the expression `[vararg*]`.

As with all other objects, an array can have ad-hoc properties. However, these are not considered to be part of the array's content and are not returned by the default enumerator (for-loop).

Where `arr` is an instance of `Array`:

```
arr.Length
```
Returns or sets the length of the array. Existing items may be truncated. This currently may insert a blank item, which conflicts with the capability to "omit" items for variadic calls. If less than the current length, items are removed.

```
arr.InsertAt(n, values*)
arr.RemoveAt(n [, length])
arr.Push(values*)
arr.Pop()
```
These are basically the same as the original object methods.

```
arr.__forin()
```
Returns an enumerator function which retrieves the array's contents, one element at a time. Yields one value for each index/position between `1` and `Length` (inclusive), regardless of which elements have been assigned values. This is normally not called directly, but invoked via `for value in arr`.

```
arr[i]
arr.Item[i]
```
`i` can be any positive index, or a zero or negative value to indicate an index relative to `Length`, with `-1` being the last element and `0` being `Length+1`.

Note that `arr[i]` is actually ambiguous in the current implementation, but is allowed for convenience, since there should be no overlap been valid indices and valid property names. Using `.Item` allows the index to be validated (an error is thrown if it is not an integer).

```
arr[i, p*]
```
Due to technical limitations, this has a mix of old and new semantics. That is, if the array element exists, `p*` is applied according to the old rules, since the meta-functions are not invoked. (This is due to the need to store array elements directly in `arr` for use with variadic calls.) In other words, `p*` is applied with `p[1]` being a property name, not as an indexer.

```
arr.Item[i, p*]
```
Equivalent to `arr.Item[i].Item[p*]` when `p` is non-empty. This is to emphasize the intention that indexing and properties be separate.