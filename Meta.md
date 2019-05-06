# Meta-Methods and a Meta-Property

## __getprop, __setprop

Called when an undefined property is accessed.

Any property defined in any of the object's bases takes precedence over the meta-methods. Compared to the original meta-functions, this restriction allows `__getprop` and `__setprop` to behave as proper methods. The original behaviour was chosen mainly to allow meta-functions to override the automatic inheritence of static variables and methods, but this is no longer a concern due to the separation of static properties, instance properties and methods.

The additional `prop` suffix is used to clarify the distinction between properties and array elements, and to avoid issues arising from the current implementation of meta-functions.

These meta-methods have two forms: with and without `args`:
```
__getprop(name)
__getprop(name, args)
__setprop(name, value)
__setprop(name, value, args)
```
Specifying `args` allows the object to implement parameterized properties, as in `x.y[z]`. `args` is currently a standard variadic-args object, not an instance of `Array`. It is a normal parameter rather than a `variadic*` one:
  - To emphasize that one must handle either all args or none.
  - To avoid repeated deconstruction and construction of the array for each base (superclass) call.
  - To possibly allow for future expansion (though utilizing any added parameters would require defining and therefore handling `args`).

If the `args` parameter is not defined (that is, if the method defines too few parameters to accept this one), the parameters are applied automatically to the return value of `__getprop` as if the "indexing operator" was called; i.e. `x.y.Item[z]` in the current script implementation.

(Similarly, if a property-getter/setter does not define *any* additional parameters, they are applied to the property-getter's return value.)

The meta-method can call one of the following to invoke the default behaviour. If `args` is provided and not empty, an exception is thrown. Otherwise, __getprop returns an empty string and __setprop defines a property value (which prevents further calls).
```
base.__getprop(name)
base.__getprop(name, args)
base.__setprop(name, value)
base.__setprop(name, value, args)
```


## __call

Called when an undefined method is called.
```
__call(name, args)
```
Note that it is `args`, not `args*`.

The default behaviour is to throw an exception. This can be invoked by calling the following:
```
base.__call(name, args)
```

## __initclass

This static method is called after a class is initialized. With the current script implementation, the class is initialized on first access (when a static member is invoked or the class is instantiated). The class can perform additional initialization, such as defining properties on its `prototype`.


## __forin

Currently called by the internal `_NewEnum` method, but the idea is that this would be called by `for`. This should return an enumerator function. See [Enumeration](readme.md#enumeration).


## __item

Added by v2.0-a101 and also utilized by this library.  Called whenever the indexing operator is used with an object, as in `obj[index]`.
```
__item[p*] {
    get {
        ...
    }
    set {
        ...
    }
}
```
