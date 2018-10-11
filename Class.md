# class Class extends Object

All classes within the Object.ahk system (that is, all direct or indirect subclasses of `Object`) are instances of `Class`. For example, `Object` itself is an object and an instance of `Class`. Its members consist of all static members defined in the `Object` class and all instance members defined in the `Class` class.

Each class has its own **prototype**. This object becomes the `base` of each instance of the class. In effect, the prototype's methods and properties become methods and properties of each instance.

A **class definition** constructs a **class object** and its **prototype**. Instance member declarations add methods and properties to the prototype, while static member declarations add methods and properties to the class object. Scripts reference the class object by name; for example, `Array` contains a reference to the Array class object.

Where `cls` is an instance of `Class` (i.e. a class):

```
cls.prototype
```
Returns or sets the class's prototype, which is the base object of each instance.

```
cls.new(p*)
```
Alternative syntax for `new cls(p*)`. The class may override this method by defining a static `new` method. There are some reasons to replace the `new` operator with a method:

  - Instantiating a class and creating an object with a given prototype (base) are now fundamentally different. Making it a method shows more clearly that the behaviour depends on the object.
  - The operator implicitly allows the creation of an object derived from an *instance*, but the same __new method is called for the initial instance and the derived instance. The class generally isn't designed to take this into account. Making the `new` method available only on the class itself means `__new` has only one, specific purpose, and will never be called unintentionally.
  - If a class author specifically wants to support creating objects derived from an instance, there can be an instance method defined for that purpose (called `new` or something else).
  - The operator always creates a new object, even if the `__new` method will return some other object (such as a singleton object or COM object). By contrast, `x.new()` can be overridden to do exactly what's needed and nothing more.
  - The operator modifies the meaning of the following identifier; e.g. the x in `x()` is a function but in `new x()` it is a variable. This language twist is probably unique to AutoHotkey, and not really necessary or intuitive.
  - Making it a method allows the object to be constructed by a COM server, such as another script or external language.

Reasons not to:

  - The method executes in static context (`this` is the class), but initialization of the new object is best performed in instance context (`this` is the new object). On the other hand, classes would override the default `new` method only if needed.
  - The need to return a different object from `__new` or construct objects across COM boundaries is rare.
  - The operator is more familiar.

Currently the method and operator work the same when given a class; that is, `new x` uses `x.prototype` as the new object's base if x is a class, or x itself if not a class.

Keeping the operator may enable further syntax extensions, such as `new Collection {Prop: 4, [1]: "first"}` to specify property and array element values. `Collection.new({...})` would not work for this if the standard object created by `{}` has no indexing capability (no array/associative array content). On the other hand, `myCol {Prop: 4, [1]: "first"}` could be translated to `(myCol.Prop := 4, myCol[1] := "first", myCol)`. That is, it could be shorthand for changing multiple properties/elements, and would naturally also work for `Collection.new() {...}`. However, it might be difficult to parse in cases like `getObject() {Prop: "to set"}` which look like function definitions.

```
cls.ToString()
```
Returns a string like "`<class MyClass>`".