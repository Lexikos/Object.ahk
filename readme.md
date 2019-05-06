# Object.ahk

This library for AutoHotkey **v2.0-a101** tests some ideas for potential changes to how objects work.

Reference:
 - [class Array](Array.md)
 - [class Class](Class.md)
 - [class Map](Map.md)
 - [class Object](Object.md)
 - [Meta-methods](Meta.md)
 - [Errors](Errors.md)

## Separate data and interface

Concept: Data items (array elements, or the object's *content*) should not mix with, or especially take precedence over, formally defined interface members.

Problem: Assigning an associative array element which coincides with a method or property causes that method or property to become inaccessible. This is a common cause of errors.

Problem: The default `base` property appears as an associative array element.

Partial solution: Separating methods from properties (see below) avoids any conflict between data and methods, but not between data and properties. This could cause an unwanted bias toward methods over properties, such as for `match.Count()` vs. `match["Count"]`.

Solution: Separate an associative array's elements from its properties/methods.
  - Store them separately
    - Many objects would use properties but have no further associative array content, so it makes sense to move that functionality to a dedicated data type. See [New Data Types](#new-data-types).
  - Separate syntax for properties vs. array elements
    - Let `obj.x` and `obj.x()` access a property or method only.
    - Let `obj[i]` perform indexing, as defined by the object's class.
    - `{a: b, c: d}` is most often used to create ad-hoc objects with known properties, so these should be properties.
    - Provide some other way to access properties with calculated names.

Associative arrays most often start out empty, so new syntax for an "associative array literal" seems unnecessary. The primary advantage of `{x: y}` is that the property names do not need to be quoted - this is consistent with `obj.x` and not with `obj["x"]`. On the other hand, the current rules also allow `{"x": y}` and any other expression which isn't a plain variable. Perhaps properties can require a `literal_identifier:` or `%variable_identifier%:` while array elements require `[index]:`.

For accessing properties with calculated names, there are a number of possibilities.
  - `obj.%name%` is a fairly obvious extension of `%varname%` and `%funcname%()`.
  - `ObjGet(obj, name)` is simple to implement and would also permit `Func("ObjGet").bind(obj)` or similar (but this is redundant since the addition of fat arrow functions).
  - `obj.[name]` is currently reserved in v2-alpha and could be used for this purpose, but it is not as visually distinct, and has misleading similarity to the indexing operator. In v1 it is an empty-named property.

Actual implementation: Objects do not allow `[]` unless an `__Item` property is defined. `Map` and `Array` define this property, and it only returns map/array elements. Currently `Array` also allows `a.1` to refer to element 1 of array `a` (there is no ambiguity because Array does not permit non-integer keys).

> **Note:** v2.0-a101 adds support for `obj.%name%` (can be followed by `[]` or `()`) and the `__Item` property, which is invoked by `obj[...]` before any meta-functions.

## Separate methods and properties

Concept: Put methods and properties into separate namespaces, just as functions and variables are separate. `obj.x` and `obj.x()` would always refer to different things.

Problem: Defining an instance variable (a.k.a. property) will override any method which has the same name. The problem may be compounded by the fact that variables and functions do not act this way.

Lesser problem: Meta-functions can be called unexpectedly in some situations. Specifically, when properties are used as associative array elements and `.base` is used to inherit elements, `methods.__get` might call the value rather than returning it. (If data and properties are separate, this might be considered a misuse of properties; but since the associative data type likely won't have built-in inheritence of data, it might be convenient.)

Solution: See *Concept* above.

Note: `obj.x := y` cannot be used to define a method at runtime. This could be seen as a loss of convenience; on the other hand, the more explicit mechanism - `obj.DefineMethod("x", y)` - is clearer, easier to search for, and much less likely to have an unintended effect.

Drawback: `aClass.aMethod` cannot be used to retrieve a reference to a method. `aClass.GetMethod("aMethod")` seems somewhat less convenient (and less stylish?). If this is really an issue, one possible solution is to come up with some new syntax for denoting a reference to a method or function. (`@aFunc` has been suggested for functions; so perhaps `aClass.@aMethod`.)

## Separate static and instance members

Concept: An instance of a class and the class itself are two different things. Properties, methods and meta-functions which are intended for instances should not automatically apply to the class itself or vice versa.

Problems:
  - A static member and an instance member with the same name cannot be defined in the same class body. Defining both requires workarounds, such as splitting the class, defining instance members in the constructor instead of the class body, or (within a method or getter/setter) checking whether `this` is a class or an instance.
  - Meta-functions defined in a class affect both instances and subclasses of the class, but are usually intended to only affect instances.
  - Subclasses and instances inherit the *values* of a "class variable", but do not inherit the variable itself; that is, `subclass.x` reflects the value of `aClass.x` until some value is assigned to the former, at which point they diverge. This may be counter-intuitive.
  - Whether a method/property is intended to be static may be unclear.

Solution: Differentiate instance members from static members. Make static members accessible only via the class in which they are defined, and instance members only via instances (of that class or any subclass). Ideally members would be defined directly in the class body, differentiated by the `static` keyword.

Actual implementation: Nested class `_static` contains static members (accessed via the class itself) and `_instance` contains instance members. Aside from these two nested classes, the class itself is kept empty to prevent conflicts and ensure the initialization meta-functions are invoked. The nested classes are eliminated during initialization, so most code should ignore them.

Side note: A method definition could (but currently doesn't) implicitly create a *static* property containing a function reference: `aClass.aMethod`. Being static-only would avoid possible confusion over `aInstance.aMethod` (which returns a Func not associated with the instance at all). See also: *Separate methods and properties* above.

## Combining the above

In summary,
  - separate data (`dict[key]`) and properties (`obj.prop`)
  - separate methods and properties
  - separate static and instance members

which means:
  - Each object may contain data (or more precisely, may support the `[]` operator), a set of properties and a set of methods.
  - Each object inherits sets of properties and methods from its class, but not the same sets that the class itself exposes.

An object might be composed of these things:
  - Properties which are simple values; each value associated with a name, independently of the data.
  - Accessor functions, called when one *gets* or *sets* a property or *calls* a method.
  - Data. What exactly would depend on the type of object.

Consider the following two potential models:
  - **Class-based model**: Every object is an instance of a class. A class defines both the members of its instances and its own static members.
  - **Prototype-based model**: Every object inherits properties and methods from its prototype or `base` object. A class definition constructs a prototype object, which becomes the base of each new instance of the class. To keep static and instance members separate, the prototype object is not the class itself.

For flexibility, an object can provide methods to define, test for, retrieve or delete the object's own properties or methods. In the prototype-based model, operating on the instance members of a class is a simple case of using these same methods on that class's prototype object. By contrast, the purely class-based model would need duplicate methods or a parameter to differentiate between static and instance members.

For objects with no formal class, properties can be shared by assigning them to an ordinary object and then using that object as a prototype. A purely class-based model could allow similar flexibility by allowing class objects to be created programmatically, but it would likely be more verbose and complex (e.g. use a class factory object to construct a class, keeping the class-construction API separate from the class's static members).

In the current v2-alpha, the class object itself is the prototype. `myObject := new myClass` creates an object with `myClass` as its prototype and `myObject is myClass` checks whether `myClass` is a prototype of `myObject`, so is true if myObject is an instance *or a subclass* of myClass.

Separating the prototype allows prototype or instance-of checks to be clarified. However, performing an instance-of check with the current `is` operator requires specifying the prototype: `x is myClass.prototype`.

## New data types

Since it was used to define properties and methods, the built-in associative capability of objects was needed by virtually all objects. If data and properties are separated, many objects will use only properties and have no need of an additional associative array. This seems a good opportunity to remove the associative array from the basic object type and introduce more specific data types, such as `Array` and `Map`.

Possible benefits:
  - Identity: the script and readers can more easily identify what kind of data the object will hold.
  - Efficiency: arrays can be made faster and more memory-efficient (more easily and effectively than optimizing the combined data type), though with some new constraints.
  - Behaviour: enumeration and indexing behaviour can be tailored to the data type. For instance, `for x in [a,b]` can enumerate `a` and `b` instead of `1` and `2`, while `aArray[-1]` can refer to the last item.

See also: [class Object](Object.md), [class Array](Array.md) and [class Map](Map.md).

## Enumeration

The current (without this script) pattern for enumeration is that each object has a single enumerator, which is initialized and returned by the object's `_NewEnum` method. The enumerator has only one method, `Next`, which either assigns values to its one or two ByRef parameters and returns `true`, or returns `false` to end enumeration.

The `x` in `for k in x` is not expected to be an enumerator, but an enumerable object. If `x` should provide some non-default form of enumeration (e.g. enumerating backwards or enumerating over properties vs. items), it is expected to create a new enumerable object. The new object might be nothing more than an enumerator-factory for `x`, or it might be a custom collection or simple array which is now separate to `x`. If the new object is created just to pass to `for`, there is a bunch of redundant work between making the call to `x` and getting at the enumerated values.

A common solution, which is also similar to how MDN recommends the JavaScript iterator protocol be implemented, is to have the enumerator return *itself* when an enumerator is requested. Specifically, `enumerator._NewEnum()` returns `enumerator`. However, this makes `_NewEnum` a misnomer and breaks from the convention established by COM (which is the origin of the name). An enumerator implementation template might look like this:

    class MyClass {
        _NewEnum() {
            return new MyClass.Enumerator(this)
        }
        class Enumerator {
            __new(parent) {
                <initialize enumerator or store parent>
            }
            Next(ByRef a, ByRef b) {
                if <no items left>
                    return false
                a := <item key>
                b := <item value>
                return true
            }
            _NewEnum() {
                return this
            }
        }
    }

A few simple changes could reduce it to this:

    class MyClass {
        __forin() {
            <initialize enumeration variables>
            return Func("Next")
            Next(ByRef a, ByRef b) {
                if <no items left>
                    return false
                a := <item key>
                b := <item value>
                return true
            }
        }
    }

Future language improvements should remove the need for `Func("Next") Next`, leaving `return (ByRef a, ByRef b) { ... }`.

The implied changes are:
  - `_NewEnum` is renamed to `__forin`. Its purpose is to provide the default enumerator function for a `for in` loop.
  - `Next` is renamed to `Call`. In other words, the object `__forin` returns can be any callable object with the appropriate signature (one or two ByRef parameters and a boolean return value). For example, it can be a `Func`, `Closure`, `BoundFunc` or a custom object.
  - To allow the use of a non-default enumerator without creating an additional enumerable object, `for` should accept an enumerator function or an enumerable object. This could be implemented one of two ways:
    1. Function objects (including the standard ones) implement a `__forin` method which returns the object itself.
    2. If `__forin` is not implemented, `for` simply assumes the value it was given is an enumerator function (but as usual, throws an exception if it can't be called).

Since `for` cannot be changed, this script does not allow enumerator functions to be passed to `for`. Instead, one can wrap it in an enumerator: `for k in new Enumerator(x.Properties())`. However, due to technical limitations regarding ByRef, the `Enumerator` class is a standard AutoHotkey class which does not extend `Object`.

Since it is more natural to enumerate an array's contents by default rather than its properties, this script removes the default enumerator for objects. That is, to enumerate an object's own properties, one needs to call `obj.Properties()` as shown above. `Array` and `Map` have default enumerators more appropriate to the specific class.


## Misc

If `x.y` contains an object (or is a property which accepts no parameters and returns an object), this library handles `x.y[z]` as `(x.y)[z]`. By contrast, current AutoHotkey versions discard `z` if `x.y` is handled by a getter/setter, unless that getter/setter explicitly accepts the parameter.


## Multi-Dimensional Arrays

Currently this script does not fully implement multi-dimensional arrays, associative or otherwise. With the basic object type no longer being a "jack of all trades", it seems appropriate to delegate multi-dimensional arrays to external libraries (or another built-in type).

AutoHotkey's limited "emulation" of multi-dimensional arrays has been useful, but is also a source of confusion when it comes to enumerating over items, cloning the array, or calling methods such as `GetAddress`. A proper multi-dim type should support the same interface as a single-dim type, only with the single index replaced with multiple.

Currently the `Map` and `Array` types translate `m[a,b]` to `m[a][b]`, but a sub-object must be explicitly assigned first. It's hard to see whether this has any real value, or just muddies the waters.

For a standard AutoHotkey object `x`, `x.y[z]` does not throw an error if `x.y` is uninitialized (as it would for `(x.y)[z]`), because it is interpreted the same as `x["y", z]`; i.e. multi-dimensional array access. That is not the case with this script.


## Object.Override.ahk

`#Include` this file in the script to override `Array()` and `Object()` (and therefore `[]` and `{}`) to return instances of `Array` and `Object`. This also removes the separate mode of `Object()` which converts an object's address to a reference. Instead of `Object(ptr)`, use `ObjFromPtr(ptr)` - ObjFromPtr is provided in Object.ahk.
