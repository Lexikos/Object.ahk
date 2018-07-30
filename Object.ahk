
class _ClassInitMetaFunctions
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
        propdata := Object_v()
        ObjRawSet(this, "←", propdata)
        ; Initialize instance variables.
        if f := b.←call["__init"] {
            ; Hackfix: __init will put values directly in propdata via ObjRawSet,
            ; but may also call methods/properties via `this` explicitly, so ←
            ; needs to refer to propdata.  This will cause issues if any methods
            ; put values directly in `this` that aren't intended for ←.
            ObjRawSet(propdata, "←", propdata)
            f.call(propdata)
            ObjDelete(propdata, "←")
        }
        ; Call constructor, *if any*.
        if f := b.←call["__new"]
            f.call(this, p*)
    }
    ; Called on classes (once only):
    __get(p*) {
        MetaClass(this)
        return this[p*]
    }
    __set(p*) {
        MetaClass(this)
        v := p.Pop()
        return this[p*] := v
    }
    __call(p*) {
        MetaClass(this)
        m := p.RemoveAt(1)
        return this[m](p*)
    }
}

class Object extends _ClassInitMetaFunctions
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
            set {
                if value is Object && ObjHasKey(value, "__Class") || value = Object
                    ObjSetBase(this, value.prototype)
                else
                    ObjSetBase(this, value)
                return value
            }
        }
        
        is(type) {
            return this is type
        }
        
        HasProperty(name) {
            m := ObjGetBase(this)
            return isObject(m.←get[name] || m.←set[name])
                || ObjHasKey(this.←, name)
        }
        
        HasMethod(name) {
            m := ObjGetBase(this)
            return isObject(m.←call[name])
        }
        
        GetMethod(name) {
            m := ObjGetBase(this)
            return m.←call[name]
        }
        
        DefineProperty(name, prop) {
            if !isObject(prop) || !(prop.get || prop.set)
                throw Exception("Invalid parameter #2", -2, prop)
            m := Own_Meta(this)
            MetaObject_DefProp(m, name, prop)
        }
        
        DefineMethod(name, func) {
            if !isObject(func)
                throw Exception("Invalid parameter #2", -2, func)
            m := Own_Meta(this)
            MetaObject_DefMeth(m, name, func)
        }
        
        DeleteProperty(name) {
            if m := Own_Meta(this, false) {
                ObjDelete(m.←get, name)
                ObjDelete(m.←set, name)
            }
            ObjDelete(this.←, name)
        }
        
        DeleteMethod(name) {
            if m := Own_Meta(this, false) {
                ObjDelete(m.←call, name)
            }
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
            if (m := ObjGetBase(this)).owner = this
                ObjSetBase(c, ObjClone(m))  ; Copy owned members, don't share.
            return c
        }
        _NewEnum() {
            return ObjNewEnum(this.←)
        }
    }
}

class Class extends Object
{
    class _instance
    {
        is(type) {
            if isObject(type)
                return type = Class || type = Object
            return this is type
        }
    }
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
            ObjSetBase(this.←, Array._Indexer)
            ObjRawSet(this, "_", this.←) ; FIXME: array elements should be separate from properties
            ObjPush(this._, p*)
        }
        
        Length {
            get {
                return this._['length']
            }
            set {
                if !(value is 'integer') || value < 0
                    throw Exception("Invalid value", -1, value)
                n := ObjLength(this._)
                if value < n
                    ObjDelete(this._, value + 1, n)
                this._['length'] := value
                return value
            }
        }
        
        InsertAt(n, values*) {
            if (length := this._['length']) != '' {
                if n <= length
                    this._['length'] := length + values.Length()
                else
                    this._['length'] := n + values.Length() - 1
            }
            return ObjInsertAt(this._, n, values*)
        }
        
        RemoveAt(n, p*) {
            if (length := this._['length']) != '' {
                if n <= length {
                    numvals := p.Length() ? p[1] : 1
                    if n + numvals > length
                        this._['length'] := n - 1
                    else
                        this._['length'] := length - numvals
                }
            }
            return ObjRemoveAt(this._, n, p*)
        }
        
        Push(values*) {
            return this.InsertAt(this.Length + 1, values*)
        }
        
        Pop() {
            return this.RemoveAt(this.Length)
        }
        
        _NewEnum() {
            return new Array.Enumerator(this)
        }
    }
    
    class Enumerator
    {
        __new(arr) {
            this._ := arr._
        }
        Next(ByRef a, ByRef b:="") {
            if IsByRef(b) {
                this.e := ObjNewEnum(this._)
                this.Next := this.base.Next2
            }
            else {
                this.Next := this.base.Next1
                this.n := 0
            }
            return this.Next(a, b)
        }
        Next1(ByRef a) {
            a := this._[++this.n]
            return this.n <= this._.length
        }
        Next2(ByRef a, ByRef b) {
            return this.e.Next(a, b)
        }
    }
    
    class _Indexer {
        length {
            get {
                return ObjLength(this)
            }
        }
        __get(index, p*) {
            if index <= 0 && index is 'integer' {
                return this[this.length + index + 1, p*]
            }
        }
        __set(index, p*) {
            if index <= 0 && index is 'integer' && p.Length() {
                value := p.Pop()
                return this[this.length + index + 1, p*] := value
            }
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
Object__get_(m, this, k, p*) {
     ; Checking for the prefix simplifies access to ←get/←set/←call
     ; and eliminates any risk of recursion by this.←[] below.
    if SubStr(k, 1, 1) != "←"
    ; The checks below ensure this isn't a subclass which has yet to be
    ; initialized.  All objects and initialized classes should have "←".
    if ObjHasKey(this, "←") || !ObjHasKey(this, "__Class") {
        if f := m[k]
            return f.call(this, p*)
        return this.←[k, p*]
    }
}
Object__set_(m, this, k, p*) {
    if ObjHasKey(this, "←") || !ObjHasKey(this, "__Class") {
        if f := m[k]
            return f.call(this, p*)
        value := p.Pop()
        return this.←[k, p*] := value
    }
}
Object__call_(m, this, k, p*) {
    if ObjHasKey(this, "←") || !ObjHasKey(this, "__Class") {
        if f := m[k]
            return f.call(this, p*)
        throw Exception("No such method", -1, k)
    }
}

class MetaObject {
    
}
MetaObject_new(owner) {
    m := Object_v()
    m.owner := &owner
    m.←get := Object_v()
    m.←set := Object_v()
    m.←call := Object_v()
    ; Set the standard meta-functions.
    m.__get := Func("Object__get_").Bind(m.←get)
    m.__set := Func("Object__set_").Bind(m.←set)
    m.__call := Func("Object__call_").Bind(m.←call)
    return m
}
MetaObject_Inherit(m, bm) {
    ObjSetBase(m.←get, bm.←get)
    ObjSetBase(m.←set, bm.←set)
    ObjSetBase(m.←call, bm.←call)
}
MetaObject_DefProp(m, name, prop) {
    (get := prop.get) && ObjRawSet(m.←get, name, get)
    (set := prop.set) && ObjRawSet(m.←set, name, set)
}
MetaObject_DefMeth(m, name, func) {
    ObjRawSet(m.←call, name, func)
}

Own_Meta(this, maycreate:=true) {
    bm := ObjGetBase(this)  ; It is assumed that 'this' is a properly constructed Object, with a meta-object.
    if bm.owner == &this
        return bm
    ; else: bm is shared.
    if !maycreate
        return
    om := MetaObject_new(this)
    MetaObject_Inherit(om, bm)
    ObjSetBase(om, bm)
    ObjSetBase(this, om)
    return om
}

Object_ReturnArg1(arg1) {
    return arg1
}

Object_Throw(message, what) {
    throw Exception(message, what)
}

Array(p*) {
    a := Object_v()
    a._ := p
    a.← := p ; FIXME: see Array.__new
    a.base := Array.prototype
    p.base := Array._Indexer
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
    if !basecls || !ObjHasKey(basecls, "__Class")
        throw Exception("Invalid parameter #1", -1, cls)
    if ObjHasKey(cls, "←instance")  ; Flag this as an error since it probably indicates a design problem.
        throw Exception("MetaClass has already been called for this class.", -1, ObjRawGet(cls, "__Class"))
    if basecls = _ClassInitMetaFunctions
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
    MakeProto(proto:="", propdata:="") {
        (proto || (proto := Object_v()))
        ObjRawSet(proto, "←", propdata || Object_v())
        ObjSetBase(proto, MetaObject_new(proto))
        return proto
    }
    ; Create instance prototype.
    pt := MakeProto()
    ; Store instance prototype as a static data property.
    ObjRawSet(static_data, "prototype", pt)
    ; Convert class to static prototype.
    MakeProto(cls, static_data)
    
    ; Store the _instance class that subclasses will link to their own.
    base_instance := basecls && basecls.←instance
    ObjRawSet(cls, "←instance", _instance || base_instance)
    
    ; (_static) && ObjRawSet(cls, "←static", _static) ; For debugging.
    
    ; Retrieve metaobjects.
    pt_m := ObjGetBase(pt)
    cls_m := ObjGetBase(cls)
    
    ; Restore the class initialization meta-functions and type identity
    ; for the `is` operator.
    ObjSetBase(cls_m, basecls || _ClassInitMetaFunctions)
    ObjSetBase(pt_m, cls)
    
    ; =================================================================
    ; Convert class members to prototype members.
    ; -----------------------------------------------------------------
    DefMembers(m, defcls) {
        e := ObjNewEnum(defcls)
        while e.Next(k, v) {
            if type(v) = "Func"
                MetaObject_DefMeth(m, k, v)
            else if type(v) = "Property"
                MetaObject_DefProp(m, k, v)
        }
    }
    (_instance) && DefMembers(pt_m, _instance)
    (_static) && DefMembers(cls_m, _static)
    
    ; Inherit superclass instance members via base prototype.
    (basecls) && MetaObject_Inherit(pt_m, ObjGetBase(basecls.prototype))
    ; Implement instance members of Class on the class object itself.
    ; This may cause a recursive call to MetaClass(Class).
    MetaObject_Inherit(cls_m, ObjGetBase(Class.prototype))
    
    if _instance {
        ; Set _instance.base to allow base.x calls.  This way, the base
        ; chain used by base.x includes only _instance members.
        ObjSetBase(_instance, base_instance)
        ; Work around base.__Init() not being called by classes with no initial base:
        if _instance.__init && base_instance && base_instance.__init
            ObjRawSet(pt_m.←call, "__init", Func("Object__init_")
                .Bind(base_instance.__init, pt_m.←call["__init"]))
    }
    if _static {
        ; Although superclass static members are not inherited, static
        ; members can override instance methods of Class or Object.
        ; Set _static.base so that base.x will call the latter.
        ObjSetBase(_static, Class.←instance)
    }
    
    ; Implement built-in base property.
    ; FIXME: Old semantics; probably should return prototype, not class.
    if !ObjHasKey(pt_m.←get, "base")
        ObjRawSet(pt_m.←get, "base", Func("Object_ReturnArg1").Bind(cls))
    if !ObjHasKey(cls_m.←get, "base")
        ObjRawSet(cls_m.←get, "base", Func("Object_ReturnArg1").Bind(basecls))
    if !ObjHasKey(cls_m.←set, "base")
        ObjRawSet(cls_m.←set, "base", Func("Object_Throw").Bind("Base class cannot be changed", -2))

    ; Evaluate static initializers (class variables defined in _static).
    if _static && ObjHasKey(_static, "__init") && type(_static.__init) == "Func" {
        ; static_data not cls, since var initializers use ObjRawSet().
        _static.__init.call(static_data)
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
    this.← := propdata := ObjClone(this)
    this.base := Object.prototype
    while ObjLength(p) {
        value := ObjPop(p), key := ObjPop(p)
        ; Could write directly to propdata, but then properties such
        ; as 'base' or any added by the user would not work.
        this[key] := value
    }
    return this
}
