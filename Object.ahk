﻿
class _Object_Property
{
}

class _Object_Base
{
    ; Called on instances:
    __init() {
        if ObjHasKey(this, "__Class")
            throw Exception(A_ThisFunc " unexpectedly called on a class", -1)
        if ObjHasKey(cls := ObjGetBase(this), "__Class") && !ObjHasKey(cls, "←")
            MetaClass(cls)
    }
    __new(p*) {
        b := ObjGetBase(this)
        ; If b is a class, make an instance; i.e. base on b.prototype.
        ; If b is an instance, make a "live clone"; i.e. base on b.
        if ObjHasKey(b, "←instance") {
            ; For `new SomeClass`, derive from `SomeClass.prototype`.
            ObjSetBase(this, b := b.prototype)
        }
        ObjRawSet(this, "←", propdata := Object_b(b.←))
        ; Initialize instance variables.
        if f := b.←method["__init"] {
            ; __init will put values directly in propdata via ObjRawSet.
            f.call(propdata)
        }
        ; Call constructor, *if any*.
        if f := this.←method["__new"]
            f.call(this, p*)
    }
    __delete() {
        if f := this.←method["__delete"]
            f.call(this)
        ; Last ref is being released, plus `this`.
        ; Any more means __delete resurrected the object.
        ObjAddRef(&this)
        if ObjRelease(&this) > 2
            return
        ; Disable accidental __delete meta-functions.
        ObjSetBase(this.←, "")
        if m := ObjRawGet(this, "←method")
            ObjSetBase(m, "")
    }
    ; Called on classes and instances:
    __get(k, p*) {
        if SubStr(k, 1, 1) = "←" {  ; An internal property.
            ; ObjLength(p) isn't checked because we want this.←method[x]
            ; to assume an empty method array if no methods are defined.
            return ""
        }
        return _Object_mget(this, this, k, p)
    }
    __set(k, p*) {
        return _Object_mset(this, this, k, p)
    }
    __call(k, p*) {
        return _Object_mcall(this, this, k, p)
    }
}

    _Object_mget(meta, this, k, p) {
        if !(props := ObjRawGet(meta, "←")) {
            MetaClass(meta)  ; Initialize class on first access.
            props := ObjRawGet(meta, "←")
        }
        loop {
            if (prop := ObjRawGet(props, k)) is _Object_Property {
                if f := prop[1] {
                    if Func_CannotAcceptParams(f, 2) {
                        prop := f.call(this)
                        break  ; Apply [p*] below.
                    }
                    return f.call(this, p*)
                }
                ; Iterate to find inherited getter, if any.
            } else {
                if prop != "" || ObjHasKey(props, k)
                    break
                ; Iterate to find inherited value, if any.
            }
            if !(props := ObjGetBase(props)) {
                if f := meta.←method["__getprop"] {
                    if Func_CannotAcceptParams(f, 3) {
                        prop := f.call(this, k)
                        break  ; Apply [p*] below.
                    }
                    return f.call(this, k, p)
                }
                break  ; Unusual: default prototype was removed or modified.
            }
        }
        ; Return property value or apply remaining parameters.
        return ObjLength(p) ? prop.Item[p*] : prop
    }

    _Object_mset(meta, this, k, p) {
        if !(thisprops := props := ObjRawGet(meta, "←")) {
            MetaClass(meta)  ; Initialize class on first access.
            thisprops := props := ObjRawGet(meta, "←")
        }
        value := p.Pop(), isaccessor := false
        loop {
            if (prop := ObjRawGet(props, k)) is _Object_Property {
                if f := prop[2] {
                    if Func_CannotAcceptParams(f, 3) {
                        if ObjLength(p)
                            return this[k].Item[p*] := value  ; Apply [p*] to property value.
                        return f.call(this, value)
                    }
                    return f.call(this, value, p*)
                }
                isaccessor := true
                ; Iterate to find inherited setter, if any.
            } else {
                if prop != "" || ObjHasKey(props, k)
                    break
                ; Iterate to find inherited value, if any.
            }
            if !(props := ObjGetBase(props)) {
                ; Treat properties with only a getter as read-only,
                ; rather than having the first assignment disable it.
                if isaccessor
                    throw Exception("Property '" k "' is read-only.", -1, k)
                if f := meta.←method["__setprop"] {
                    if Func_CannotAcceptParams(f, 4) {
                        if ObjLength(p)
                            return this[k].Item[p*] := value  ; Apply [p*] to property value.
                        return f.call(this, k, value)
                    }
                    return f.call(this, k, value, p)
                }
                break  ; Unusual: default prototype was removed or modified.
            }
        }
        ; Store property value or apply remaining parameters.
        if ObjLength(p)
            return prop.Item[p*] := value
        if meta != this {
            if !isObject(this)
                throw Exception("Primitive values cannot be assigned properties.", -2, this)
            thisprops := ObjRawGet(this, "←")
        }
        ObjRawSet(thisprops, k, value)
        return value
    }

    _Object_mcall(meta, this, k, p) {
        if !ObjHasKey(meta, "←")
            MetaClass(meta)  ; Initialize class on first access.
        if f := meta.←method[k]
            return f.call(this, p*)
        if f := meta.←method["__call"]
            return f.call(this, k, p)
        ; Unusual case: default prototype was removed or modified.
        throw Exception("Unknown method", -2, k)
    }

class Object extends _Object_Base
{
    class _instance
    {
        base {
            get {
                return (b := ObjGetBase(this)) = _Object_Base ? "" : b
            }
            set {
                if value = "" {
                    ObjSetBase(this, _Object_Base)
                    ObjSetBase(this.←, "")
                    if (tm := ObjRawGet(this, "←method"))
                        ObjSetBase(tm, "")
                } else {
                    if !(value_← := ObjRawGet(value, "←"))
                        throw Exception("Incompatible base object", -1, type(value))
                    ObjSetBase(this, value)
                    ObjSetBase(this.←, value_←)
                    if (tm := ObjRawGet(this, "←method"))
                        ObjSetBase(tm, Object_own_←method(value))
                }
                return value
            }
        }
        
        HasProperty(name) {
            return Object_HasProp(this, name)
        }
        
        HasOwnProperty(name) {
            return ObjHasKey(this.←, name)
        }
        
        HasMethod(name) {
            return Object_HasMeth(this, name)
        }
        
        GetMethod(name) {
            return Object_GetMeth(this, name)
        }
        
        DefineProperty(name, prop) {
            if !isObject(prop) || !(prop.get || prop.set)
                throw Exception("Invalid parameter #2", -3, prop)
            Object_DefProp(this, name, prop)
        }
        
        DefineMethod(name, func) {
            if !isObject(func)
                throw Exception("Invalid parameter #2", -3, func)
            Object_DefMeth(this, name, func)
        }
        
        DeleteProperty(name) {
            ObjDelete(this.←, name)
        }
        
        DeleteMethod(name) {
            if tm := ObjRawGet(this, "←method")
                ObjDelete(tm, name)
        }
        
        ; Standard object methods
        SetCapacity(p*) {
            return ObjSetCapacity(this.←, p*)
        }
        GetCapacity(p*) {
            return ObjGetCapacity(this.←, p*)
        }
        GetAddress(p) {
            return ObjGetAddress(this.←, p)
        }
        Clone() {
            c := ObjClone(this)
            ObjRawSet(c, "←", ObjClone(this.←))  ; Copy owned properties, don't share.
            if tm := ObjRawGet(this, "←method")
                ObjRawSet(c, "←method", ObjClone(tm))  ; Copy owned methods.
            return c
        }
        
        Properties() {
            e := ObjNewEnum(this.←)
            Next(ByRef a, ByRef b:="") {
                if !e.Next(a, b)
                    return false
                ; For now, exceptions are suppressed rather than locating
                ; the property getter and determining if it requires an index.
                if b is _Object_Property && IsByRef(b)
                    try b := this[a]
                return true
            }
            return Func("Next")
        }
        
        ; Meta-methods - called only if no member exists in any prototype.
        ; args is a standard variadic-args object, not an Array.
        __getprop(name, args:=0) {
            if args && ObjLength(args)
                return "".Item[args*]
            return ""
        }
        __setprop(name, value, args:=0) {
            if args && ObjLength(args)
                return "".Item[args*]
                ; throw Exception("No object to invoke.", -3, name)
            ObjRawSet(this.←, name, value)
            return value
        }
        __call(name, args) {
            throw Exception("Unknown method", -3, name)
        }
        
        ; Adapt old interface to new.
        _NewEnum() {
            try
                return new Enumerator(this.__forin())
            catch ex
                throw Exception(ex.Message, -2)
        }
        
        __forin() {
            throw Exception("No default enumerator", -2)
        }
    }
}

class Class extends Object
{
    class _instance
    {
        new(p*) {
            return new this(p*)
        }
    }
}

class Enumerator ; This is an old-style class due to the need for ByRef.
{
    __new(f) {
        this.f := f
    }
    
    Next(ByRef a, ByRef b:="") {
        return %this.f%(a, IsByRef(b) ? b : "")
    }
    
    _NewEnum() {
        return this
    }
    
    __forin() {
        return this.f
    }
}

class Array extends Object
{
    class _instance
    {
        __new(values*) {
            ObjLength(values) && ObjInsertAt(this, 1, values*)
        }
        
        Length {
            get {
                return ObjLength(this)
            }
            set {
                if !(value is 'integer') || value < 0
                    throw Exception("Invalid value", -1, value)
                if value < (n := ObjLength(this))
                    ObjDelete(this, value + 1, n)
                if !ObjHasKey(this, value)
                    ObjRawSet(this, value, "")
                return value
            }
        }
        
        InsertAt(n, values*) {
            return ObjInsertAt(this, n, values*)
        }
        
        RemoveAt(n, p*) {
            return ObjRemoveAt(this, n, p*)
        }
        
        Push(values*) {
            return ObjPush(this, values*)
        }
        
        Pop() {
            return ObjPop(this)
        }
        
        __getprop(index, args) {
            if index is 'integer' && index <= 0
                return this[index + ObjLength(this) + 1, args*]
            return base.__getprop(index, args)
        }
        
        __setprop(index, value, args) {
            if index is 'integer'  {
                if index <= 0
                    return this[index + ObjLength(this) + 1, args*] := value
                if !ObjLength(args) {
                    ObjRawSet(this, index, value)
                    return value
                }
            }
            return base.__setprop(index, value, args)
        }
        
        Item[index, p*] {
            get {
                if !(index is 'integer')
                    throw Exception("Invalid index", -3, index)
                v := ObjRawGet(this, index + (index <= 0 ? ObjLength(this) + 1 : 0))
                return ObjLength(p) ? v.Item[p*] : v
            }
            set {
                if !(index is 'integer')
                    throw Exception("Invalid index", -3, index)
                (index <= 0) && (index += ObjLength(this) + 1)
                if ObjLength(p)
                    return ObjRawGet(this, index).Item[p*] := value
                ObjRawSet(this, index, value)
                return value
            }
        }
        
        __forin() {
            n := 0
            Next(ByRef a) {
                a := this[++n]
                return n <= ObjLength(this)
            }
            return Func("Next")
        }
    }
}

class Map extends Object
{
    class _instance
    {
        __new() {
            ObjRawSet(this, "←map", Object_v())
        }
        
        Has(key) {
            return ObjHasKey(this.←map, Map_key(key))
        }
        
        Item[key, p*] {
            get {
                v := ObjRawGet(this.←map, Map_key(key))
                return ObjLength(p) ? v.Item[p*] : v
            }
            set {
                if ObjLength(p) {
                    v := ObjRawGet(this.←map, Map_key(key))
                    return v.Item[p*] := value
                }
                ObjRawSet(this.←map, Map_key(key), value)
                return value
            }
        }
        
        Count {
            get {
                return ObjCount(this.←map)
            }
        }
        
        Delete(key) {
            return ObjDelete(this.←map, Map_key(key))
        }
        
        Clear() {
            this.__new()
        }
        
        Clone() {
            ObjRawSet(cl := base.Clone(), "←map", ObjClone(this.←map))
            return cl
        }
        
        __forin() {
            e := ObjNewEnum(this.←map)
            Next(ByRef a, ByRef b) {
                if !e.Next(a, b)
                    return false
                a := Map_unkey(a)
                return true
            }
            return Func("Next")
        }
    }
}

Map_key(key) {
    ; Make keys case-sensitive and differentiate "1" from 1.
    return Type(key) = 'String'
        ? RegExReplace(key, "\p{Lu}|\x01|^\s*[+-]?\.?\d", chr(1) "$0")
        : key
}

Map_unkey(key) {
    return Type(key) = 'String'
        ? key is 'float' ; Never true for keys that are originally strings, due to escaping.
            ? Float(key)
            : RegExReplace(key, "\x01(.)", "$1")
        : key
}

Object__init_(fsuper, f, this) {
    fsuper.call(this)
    f.call(this)
}

Object_own_←method(this) {
    if !(tm := ObjRawGet(this, "←method")) {
        ObjRawSet(this, "←method", tm := Object_v())
        if (b := ObjGetBase(this)) != _Object_Base
            ObjSetBase(tm, Object_own_←method(b))  ; Recursive call to build proper inheritence chain.
    }
    return tm
}

Object_DefProp(this, name, propdesc) {
    if !((prop := ObjRawGet(this.←, name)) is _Object_Property)
        ObjRawSet(this.←, name, prop := new _Object_Property)
    (get := propdesc.get) && prop[1] := get
    (set := propdesc.set) && prop[2] := set
}
Object_DefMeth(this, name, func) {
    ObjRawSet(Object_own_←method(this), name, func)
}

Object_HasProp(this, name) {
    props := isObject(this) ? this.← : this.base.←
    Loop
        if ObjHasKey(props, name)
            return true
    until !(props := ObjGetBase(props))
    return false
}

Object_HasMeth(this, name) {
    return isObject(this.←method[name])
}

Object_GetMeth(this, name) {
    return this.←method[name]
}

Object_v(p*) {
    return p
}

Object_b(base, p*) {
    ObjSetBase(p, base)
    return p
}

Func_CannotAcceptParams(f, n) {
    mp := "", iv := false
    try mp := f.MaxParams, iv := f.IsVariadic
    return mp is 'integer' && mp < n && !iv
}

_throw_Immutable(this) {
    throw Exception("This object of type '" type(this) "' is immutable.", -3, this)
}

_throw(m, n := -1, e := "") {
    throw Exception(m, n is 'integer' && n < 0 ? n-1 : n, e)
}

; =====================================================================
; MetaClass(cls): Initializes a class object to enable new semantics.
; =====================================================================
MetaClass(cls) {
    ; Determine base class.
    basecls := ObjGetBase(cls)  ; cls.base won't work for subclasses if MetaClass(superclass) has been called.
    if !ObjHasKey(cls, "__Class") || !basecls || !ObjHasKey(basecls, "__Class")
        throw Exception("Invalid parameter #1", -1, cls)
    if ObjHasKey(cls, "←instance")  ; Flag this as an error since it probably indicates a design problem.
        throw Exception("MetaClass has already been called for this class.", -1, ObjRawGet(cls, "__Class"))
    if basecls = _Object_Base
        basecls := ""
    else if !ObjHasKey(basecls, "←") {
        MetaClass(basecls)  ; Initialize base class first.
        if ObjHasKey(cls, "←instance")
            return ; Handled by recursion, such as for Class/Object.
    }
    ; Retrieve and remove internal properties.
    _instance := ObjDelete(cls, "_instance")
    _static := ObjDelete(cls, "_static")
    ; Retrieve and remove nested classes.
    static_data := Object_v()
    e := ObjNewEnum(cls)
    while e.Next(k, v) {
        if type(v) == "Class"  ; Nested class (static variables should be in _static).
            ObjRawSet(static_data, k, v)
        else if k != "__Class"
            throw Exception(Format("Improper static data {1}:{2} in class {3}."
                , IsObject(k) ? Type(k) : "'" k "'"
                , IsObject(v) ? Type(v) : "'" v "'"
                , cls.__class), -1)
    }
    e := ObjNewEnum(static_data)
    while e.Next(k)
        ObjDelete(cls, k)
    
    ; =================================================================
    ; Initialize core objects.
    ; -----------------------------------------------------------------
    ; Create instance prototype.
    pt := Object_v()
    ObjRawSet(pt, "←", Object_v())
    ; Store instance prototype as a static data property.
    ObjRawSet(static_data, "prototype", pt)
    ; Convert class.
    ObjRawSet(cls, "←", static_data)
    
    ; Set __class to assist debugging and provide a meaningful string for
    ; type(), with the side-effect that prototypes are considered classes:
    ObjRawSet(pt, "__class", cls.__class)
    
    ; Store the _instance class that subclasses will link to their own.
    base_instance := basecls && basecls.←instance
    ObjRawSet(cls, "←instance", _instance || base_instance)
    
    ; (_static) && ObjRawSet(cls, "←static", _static) ; For debugging.
    
    ; Set up inheritence.
    if basecls {
        ; Set base for `is` and `.base`.
        ObjSetBase(pt, basept := basecls.prototype)
        ; Inherit superclass instance members via base prototype.
        ObjSetBase(pt.←, basept.←)
    } else {
        ; Set the (hidden) root base object to make it all work.
        ObjSetBase(pt, _Object_Base)
    }
    if !ObjHasKey(Class, "←")
        MetaClass(Class)
    ObjSetBase(cls, Class_pt := Class.prototype)
    ; Implement instance members of Class on the class object itself.
    ObjSetBase(static_data, Class_pt.←)
    
    ; =================================================================
    ; Convert class members to prototype members.
    ; -----------------------------------------------------------------
    DefMembers(pt, defcls) {
        e := ObjNewEnum(defcls)
        while e.Next(k, v) {
            if type(v) = "Func"
                Object_DefMeth(pt, k, v)
            else if type(v) = "Property"
                Object_DefProp(pt, k, v)
        }
    }
    (_instance) && DefMembers(pt, _instance)
    (_static) && DefMembers(cls, _static)
    
    if _instance {
        ; Set _instance.base to allow base.x calls.  This way, the base
        ; chain used by base.x includes only _instance members.
        ObjSetBase(_instance, base_instance)
        ; Work around base.__Init() not being called by classes with no initial base:
        if _instance.__init && base_instance && base_instance.__init
            ObjRawSet(pt.←method, "__init", Func("Object__init_")
                .Bind(basept.←method["__init"], pt.←method["__init"]))
    }
    if _static {
        ; Although superclass static members are not inherited, static
        ; members can override instance methods of Class or Object.
        ; Set _static.base so that base.x will call the latter.
        ObjSetBase(_static, Class.←instance)
    }
    
    ; Evaluate static initializers (class variables defined in _static).
    if f := cls.←method["__init"] {
        ; static_data not cls, since var initializers use ObjRawSet().
        f.call(static_data)
    }
    ; Allow for the static equivalent of __new (or static constructor).
    if f := cls.←method["__initclass"]
        f.call(cls)
}
