
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
        ObjRawSet(this, "←", propdata := new b.←)
        ; Initialize instance variables.
        if f := b.←method["__init"] {
            ; __init will put values directly in propdata via ObjRawSet.
            f.call(propdata)
        }
        ; Call constructor, *if any*.
        if f := b.←method["__new"]
            f.call(this, p*)
    }
    ; Called on classes and instances:
    __get(k, p*) {
        if !(props := ObjRawGet(this, "←")) {
            MetaClass(this)  ; Initialize class on first access.
            props := ObjRawGet(this, "←")
        }
        if SubStr(k, 1, 1) != "←" {  ; Not an inheritable internal property such as .←method.
            loop {
                if (prop := ObjRawGet(props, k)) is _Object_Property {
                    if f := prop[1]
                        return f.call(this, p*)
                    ; Iterate to find inherited getter, if any.
                } else {
                    if prop != "" || ObjHasKey(props, k)
                        break
                    ; Iterate to find inherited value, if any.
                }
                if !(props := ObjGetBase(props)) {
                    if f := this.←method["__getprop"]
                        return f.call(this, k, p)
                    break  ; Unusual: default prototype was removed or modified.
                }
            }
            ; Return property value or apply remaining parameters.
            ; FIXME: Apply item indexing semantics rather than property semantics.
            return ObjLength(p) ? prop[p*] : prop
        }
    }
    __set(k, p*) {
        if !(thisprops := props := ObjRawGet(this, "←")) {
            MetaClass(this)  ; Initialize class on first access.
            thisprops := props := ObjRawGet(this, "←")
        }
        value := p.Pop(), isaccessor := false
        loop {
            if (prop := ObjRawGet(props, k)) is _Object_Property {
                if f := prop[2]
                    return f.call(this, value, p*)
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
                if f := this.←method["__setprop"]
                    return f.call(this, k, value, p)
                break  ; Unusual: default prototype was removed or modified.
            }
        }
        ; Store property value or apply remaining parameters.
        ; FIXME: Apply item indexing semantics rather than property semantics.
        if ObjLength(p)
            return prop[p*] := value
        ObjRawSet(thisprops, k, value)
        ; thisprops[k] := value
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
        HasKey(p) {
            return ObjHasKey(this.←, p)
        }
        Clone() {
            c := ObjClone(this)
            ObjRawSet(c, "←", ObjClone(this.←))  ; Copy owned properties, don't share.
            if tm := ObjRawGet(this, "←method")
                ObjRawSet(c, "←method", ObjClone(tm))  ; Copy owned methods.
            return c
        }
        _NewEnum() {
            ; FIXME: enumeration of accessor properties should not return the property descriptor
            return ObjNewEnum(this.←)
        }
        
        ; Meta-methods - called only if no member exists in any prototype.
        ; args is a standard variadic-args object, not an Array.
        __getprop(name, args) {
            if ObjLength(args)
                throw Exception("No object to invoke.", -2, name)
            return ""
        }
        __setprop(name, value, args) {
            if ObjLength(args)
                throw Exception("No object to invoke.", -2, name)
            ObjRawSet(this.←, name, value)
            return value
        }
        __call(name, args) {
            throw Exception("Unknown method", -2, name)
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
        __new(p*) {
            ObjRawSet(this, "←items", p)
        }
        
        Length {
            get {
                return ObjLength(this.←items)
            }
            set {
                if !(value is 'integer') || value < 0
                    throw Exception("Invalid value", -1, value)
                if value < (n := ObjLength(items := this.←items))
                    ObjDelete(items, value + 1, n)
                if !ObjHasKey(items, value)
                    ObjRawSet(items, value, "")
                return value
            }
        }
        
        InsertAt(n, values*) {
            return ObjInsertAt(this.←items, n, values*)
        }
        
        RemoveAt(n, p*) {
            return ObjRemoveAt(this.←items, n, p*)
        }
        
        Push(values*) {
            return ObjPush(this.←items, values*)
        }
        
        Pop() {
            return ObjPop(this.←items)
        }
        
        _NewEnum() {
            return new Array.Enumerator(this)
        }
        
        _[index, p*] {
            get {
                if !(index is 'integer')
                    throw Exception("Invalid index", -2, index)
                items := this.←items
                return items[index + (index <= 0 ? ObjLength(items) + 1 : 0), p*]
            }
            set {
                if !(index is 'integer')
                    throw Exception("Invalid index", -2, index)
                items := this.←items
                return items[index + (index <= 0 ? ObjLength(items) + 1 : 0), p*] := value
            }
        }
    }
    
    class Enumerator
    {
        __new(arr) {
            this.arr := arr
        }
        Next(ByRef a, ByRef b:="") {
            if IsByRef(b) {
                this.Next := this.base.Next2
                this.e := ObjNewEnum(this.arr.←)
            }
            else {
                this.Next := this.base.Next1
                this.arr := this.arr.←items
                this.n := 0
            }
            return this.Next(a, b)
        }
        Next1(ByRef a) {
            a := (arr := this.arr)[n := ++this.n]
            return n <= ObjLength(arr)
        }
        Next2(ByRef a, ByRef b) {
            return this.e.Next(a, b)
        }
    }
}

class Map_Key {
}
class Map extends Object
{
    class _instance
    {
        __new() {
            ObjRawSet(this, Map_Key, Object_v())
        }
        
        Has(key) {
            return ObjHasKey(this[Map_Key], RegExReplace(key, "\p{Lu}|\x01", chr(1) "$0"))
        }
        
        Get(key) {
            return this[Map_Key, RegExReplace(key, "\p{Lu}|\x01", chr(1) "$0")]
        }
        
        Set(key, value) {
            ObjRawSet(this[Map_Key], RegExReplace(key, "\p{Lu}|\x01", chr(1) "$0"), value)
            return value
        }
        
        Count {
            get {
                return ObjCount(this[Map_Key])
            }
            set {
                throw Exception("Count is read-only", -1)
            }
        }
        
        Clone() {
            ObjRawSet(cl := base.Clone(), Map_Key, ObjClone(this[Map_Key]))
            return cl
        }
        
        ; _NewEnum() {
            ; TODO
        ; }
    }
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

Array(p*) {
    a := Object_v()
    b := Array.prototype
    a.← := new b.←
    a.←items := p
    a.base := b
    return a
}

Object_v(p*) {
    return p
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
    ObjRawSet(this, "←", new b.←)
    while ObjLength(p) {
        value := ObjPop(p), key := ObjPop(p)
        ; Could write directly to propdata, but then properties such
        ; as 'base' or any added by the user would not work.
        this[key] := value
    }
    return this
}
