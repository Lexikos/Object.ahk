# class Object

The top-level base class of all objects within the Object.ahk system.

If `Object.Override.ahk` is used, objects created by `{}` and `Object()` are instances of `Object`.

Where `obj` is an instance of `Object`:

```
obj.base
```
Returns or sets the object's prototype (the object on which it is based; properties and methods are inherited from this object). This is not the object's class, but if `cls` is the object's class, `cls.prototype = obj.base`. When setting a new base, the new base must be an object created within the Object.ahk system (otherwise inheritence would not work).

```
obj.HasOwnProperty(name)
```
Returns true if the object owns a given property; i.e. it is stored or defined in the object itself, not just inherited.

```
obj.HasProperty(name)
obj.HasMethod(name)
```
Returns true if the object has a given property or method, whether it was defined in a class or using a Define method. However, to test for an instance method, *obj* must be an instance (or the class's prototype).

```
obj.GetMethod(name)
```
Returns the Func corresponding to a method, if one exists. To retrieve an instance method, *obj* must be an instance (or the class's prototype). May return an inherited method.

```
obj.DefineProperty(name, prop)
```
Defines a property. `prop.get` and `prop.set` should return the corresponding functions. If false/empty, that component is left unchanged and may be inherited. However, if a property has a getter and no setter, it is read-only (throws on assignment).

```
obj.DefineMethod(name, func)
```
Defines a method. To define an instance method for all instances of a class, let *obj* be the class's prototype.

```
obj.DeleteProperty(name)
obj.DeleteMethod(name)
```
Undefines an object's own property or method. Does not affect inherited properties or methods. To undefine an instance method previously defined in a class, let *obj* be the class's prototype.

```
obj.SetCapacity([name,] capacity)
obj.GetCapacity([name])
obj.GetAddress(name)
```
Approximately the same as the usual methods, but they operate on the object's properties (or its internal array of properties). These should be replaced with a separate binary data type (e.g. byte buffer object).

```
obj.Clone()
```
Returns a shallow copy of the object. This must be used instead of `ObjClone(obj)`, due to how properties and methods are stored. Custom classes should override it.

```
obj.Properties()
```
Returns an enumerator function which retrieves the object's own property names or name-value pairs. If the function's second parameter is a variable, property-getters are called if necessary to give this variable the property's value. Meta-methods are not called, since the function only returns properties that exist.

```
obj.ToString()
```
Produces a basic string to identify the object, such as "`<Object at 0xDEADBEEF>`", "`<Map at 0xBADFOOD>`", or "`<MyClass.prototype>`". This can be used indirectly by `String(obj)`, which is used for the "additional info" (second parameter) passed when constructing an `Exception`.

```
obj._NewEnum()
```
This is an internal method used to adapt the current implementation of `for` to the idea of [__forin](readme.md#enumeration).
