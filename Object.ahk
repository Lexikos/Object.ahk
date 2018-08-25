
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
        if ObjHasKey(b, "__Class") {
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
        if !(props := ObjRawGet(this, "←")) {
            MetaClass(this)  ; Initialize class on first access.
            props := ObjRawGet(this, "←")
        }
        if SubStr(k, 1, 1) = "←" {  ; An internal property.
            ; ObjLength(p) isn't checked because we want this.←method[x]
            ; to assume an empty method array if no methods are defined.
            return ""
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
                if f := this.←method["__getprop"] {
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
    __set(k, p*) {
        if !(thisprops := props := ObjRawGet(this, "←")) {
            MetaClass(this)  ; Initialize class on first access.
            thisprops := props := ObjRawGet(this, "←")
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
                if f := this.←method["__setprop"] {
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
        ObjRawSet(thisprops, k, value)
        return value
    }
    __call(k, p*) {
        if !ObjHasKey(this, "←")
            MetaClass(this)  ; Initialize class on first access.
        if f := this.←method[k]
            return f.call(this, p*)
        if f := this.←method["__call"]
            return f.call(this, k, p)
        ; Unusual case: default prototype was removed or modified.
        throw Exception("Unknown method", -1, k)
    }
}

class Object extends _Object_Base
{
    class _static
    {
        new(p*) {
            return new this(p*)
        }
    }
    
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
            props := this.←
            Loop
                if ObjHasKey(props, name)
                    return true
            until !(props := ObjGetBase(props))
            return false
        }
        
        HasOwnProperty(name) {
            return ObjHasKey(this.←, name)
        }
        
        HasMethod(name) {
            return isObject(this.←method[name])
        }
        
        GetMethod(name) {
            return this.←method[name]
        }
        
        DefineProperty(name, prop) {
            if !isObject(prop) || !(prop.get || prop.set)
                throw Exception("Invalid parameter #2", -2, prop)
            Object_DefProp(this, name, prop)
        }
        
        DefineMethod(name, func) {
            if !isObject(func)
                throw Exception("Invalid parameter #2", -2, func)
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
        _NewEnum() {
            return new Object.Enumerator(this)
        }
        
        ; Meta-methods - called only if no member exists in any prototype.
        ; args is a standard variadic-args object, not an Array.
        __getprop(name, args:=0) {
            if args && ObjLength(args)
                throw Exception("No object to invoke.", -2, name)
            return ""
        }
        __setprop(name, value, args:=0) {
            if args && ObjLength(args)
                throw Exception("No object to invoke.", -2, name)
            ObjRawSet(this.←, name, value)
            return value
        }
        __call(name, args) {
            throw Exception("Unknown method", -2, name)
        }
    }
    
    class Enumerator
    {
        __new(obj) {
            this.obj := obj
            this.e := ObjNewEnum(obj.←)
        }
        
        Next(ByRef a, ByRef b:="") {
            if !this.e.Next(a, b)
                return false
            ; For now, exceptions are suppressed rather than locating
            ; the property getter and determining if it requires an index.
            if b is _Object_Property && IsByRef(b)
                try b := this.obj[a]
            return true
        }
    }
}

class Class extends Object
{
}

Value__call(value, n, p*) {
    static _ := ("".base.__call := Func("Value__call"), 0)
    if n = "is"
        return value is p[1]
}

class Array extends Object
{
    class _instance
    {
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
        
        _NewEnum() {
            return new Array.Enumerator(this)
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
                    throw Exception("Invalid index", -2, index)
                return this[index + (index <= 0 ? ObjLength(this) + 1 : 0), p*]
            }
            set {
                if !(index is 'integer')
                    throw Exception("Invalid index", -2, index)
                return this[index + (index <= 0 ? ObjLength(this) + 1 : 0), p*] := value
            }
        }
    }
    
    class Enumerator
    {
        __new(arr) {
            this.arr := arr
            this.n := 0
        }
        Next(ByRef a, ByRef b:="") {
            return (this.Next := this.base["Next" 1+IsByRef(b)]).call(this, a, b)
        }
        Next1(ByRef a) {
            a := (arr := this.arr)[n := ++this.n]
            return n <= ObjLength(arr)
        }
        Next2(ByRef a, ByRef b) {
            if (a := ++this.n) <= ObjLength(arr := this.arr) {
                b := arr[a]
                return true
            }
            this.e := ObjNewEnum(this.arr.←)
            this.Next := this.base.Next2e
            return this.Next(a, b)
        }
        Next2e(ByRef a, ByRef b) {
            return this.e.Next(a, b)
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
        
        Clone() {
            ObjRawSet(cl := base.Clone(), "←map", ObjClone(this.←map))
            return cl
        }
        
        _NewEnum() {
            return new Map.Enumerator(this)
        }
    }
    
    class Enumerator
    {
        __new(map) {
            this.e := ObjNewEnum(map.←map)
        }
        
        Next(ByRef a, ByRef b) {
            if !this.e.Next(a, b)
                return false
            a := Map_unkey(a)
            return true
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
    ObjRawSet(this.←, name, prop := new _Object_Property)
    prop[1] := propdesc.get, prop[2] := propdesc.set
}
Object_DefMeth(this, name, func) {
    ObjRawSet(Object_own_←method(this), name, func)
}

Array(a*) {
    b := Array.prototype
    a.← := Object_b(b.←)
    a.base := b
    return a
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
    else if !ObjHasKey(basecls, "←")
        MetaClass(basecls)  ; Initialize base class first.
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
                , cls.__class), -2)
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


;
; Bad code! Version-dependent. Relies on undocumented stuff.
;

ObjCount(obj) {
    return NumGet(&obj+4*A_PtrSize)
}

Object(p*) {
    if ObjLength(p) & 1 {
        if p.Length() = 1
            return ComObject(0x4009, &(n := p[1]))[]
        throw Exception("Invalid parameter count", -1, ObjLength(p))
    }
    ; This is just the essential parts of what `new Object()` does,
    ; skipping stuff that isn't needed, under the assumption that no
    ; one will add __init or __new methods to class Object.
    this := Object_v()
    ObjSetBase(this, b := Object.prototype)
    ObjRawSet(this, "←", Object_b(b.←))
    while ObjLength(p) {
        value := ObjPop(p), key := ObjPop(p)
        ; Could write directly to propdata, but then properties such
        ; as 'base' or any added by the user would not work.
        this[key] := value
    }
    return this
}
