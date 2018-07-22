
class _ClassInitMetaFunctions
{
    ; Called on instances:
    __init() {
        if ObjHasKey(this, "__Class")
            throw Exception(A_ThisFunc " unexpectedly called on a class", -1)
        cls := ObjGetBase(this)
        if !ObjHasKey(cls, "__Class")
            throw Exception("new unexpectedly used with a non-class", -1)
        pm := Class_ProtoMeta(cls)
        if f := pm.m.call["__init"]
            f.call(this)
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
                    ObjSetBase(this, Class_ProtoMeta(value))
                else
                    ObjSetBase(this, value)
                return value
            }
        }
        
        is(type) {
            return this is type
        }
        
        HasProperty(name) {
            mo := ObjGetBase(this)
            return isObject(mo.m.get[name] || mo.m.set[name])
                || ObjHasKey(this._, name)
                ; || ObjHasKey(this, name)
        }
        
        HasMethod(name) {
            mo := ObjGetBase(this)
            return isObject(mo.m.call[name])
        }
        
        DefineProperty(name, prop) {
            if !isObject(prop) || !(prop.get || prop.set)
                throw Exception("Invalid parameter #2", -2, prop)
            mo := Own_Meta(this)
            Members_DefProp(mo.m, name, prop)
        }
        
        DefineMethod(name, func) {
            if !isObject(func)
                throw Exception("Invalid parameter #2", -2, func)
            mo := Own_Meta(this)
            Members_DefMeth(mo.m, name, func)
        }
        
        DeleteProperty(name) {
            if mo := Own_Meta(this, false) {
                ObjDelete(mo.m.get, name)
                ObjDelete(mo.m.set, name)
            }
            ObjDelete(this._, name)
        }
        
        DeleteMethod(name) {
            if mo := Own_Meta(this, false) {
                ObjDelete(mo.m.call, name)
            }
        }
        
        ; Standard object methods
        SetCapacity(p*) {
            return ObjSetCapacity(this._, p*)
        }
        GetCapacity(p*) {
            return ObjGetCapacity(this._, p*)
        }
        GetAddress(p) {
            return ObjGetAddress(this._, p)
        }
        HasKey(p) {
            return ObjHasKey(this._, p)
        }
        Clone() {
            return {_: ObjClone(this._), base: this.base}
        }
        _NewEnum() {
            return ObjNewEnum(this._)
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
        __new() {
            ObjSetBase(this._, Array._Indexer)
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
        
        _NewEnum() {
            return ObjNewEnum(this._)  ; TODO
        }
    }
}

Object__new_(pm, f, this) {
    self := Object_v()
    ; This reuses the original object for data storage, since it already
    ; contains the ad hoc properties which were created in __init.
    ; FIXME: It's probably better to have property-assignment semantics,
    ;  not direct-to-data (i.e. property setters should be called).
    self._ := this
    self.base := pm
    ObjSetBase(this, "")
    (f) && f.call(self)
    return self
}
Object__init_(f, this) {
    f.call(this)
}
Object__get_(b, m, this, k, p*) {
    if &ObjGetBase(this) = b {  ; Workaround for subclasses which haven't yet been metaclass()ed.
        if f := m[k]
            return f.call(this, p*)
        return this._[k, p*]
    }
}
Object__set_(b, m, this, k, p*) {
    if &ObjGetBase(this) = b {
        if f := m[k]
            return f.call(this, p*)
        value := p.Pop()
        return this._[k, p*] := value
    }
}
Object__call_(b, m, this, k, p*) {
    if &ObjGetBase(this) = b {
        if f := m[k]
            return f.call(this, p*)
        throw Exception("No such method", -1, k)
    }
}

class Class_ProtoMeta_Key {
}
Class_ProtoMeta(cls) {
    if !ObjHasKey(cls, Class_ProtoMeta_Key)
        MetaClass(cls)
    return cls[Class_ProtoMeta_Key]
}

class MetaObject {
    
}
MetaObject_new(m) {
    mo := Object_v()
    mo.__get := Func("Object__get_").Bind(&mo, m.get)
    mo.__set := Func("Object__set_").Bind(&mo, m.set)
    mo.__call := Func("Object__call_").Bind(&mo, m.call)
    mo.m := m
    return mo
}

Own_Meta(this, maycreate:=true) {
    mo := ObjGetBase(this)  ; It is assumed that 'this' is a properly constructed Object, with a meta-object.
    if mo.owner == &this
        return mo
    ; else: mo is shared.
    if !maycreate
        return
    m := Members_new()
    tm := MetaObject_new(m)
    tm.owner := &this
    Members_Inherit(m, mo.m)
    ObjSetBase(this, tm)
    return tm
}

Object_ReturnArg1(arg1) {
    return arg1
}

Object_Throw(message, what) {
    throw Exception(message, what)
}

class Class_Members_Key {
}
Members_new() {
    m := Object_v()
    m.get := Object_v()
    m.set := Object_v()
    m.call := Object_v()
    ; ObjRawSet(m.get, "base", "") ; Removes the need for ObjRawSet elsewhere, but makes debugging harder.
    ; ObjRawSet(m.set, "base", "")
    ; ObjRawSet(m.call, "base", "")
    return m
}
Members_Inherit(m, bm) {
    ObjSetBase(m.get, bm.get)
    ObjSetBase(m.set, bm.set)
    ObjSetBase(m.call, bm.call)
}
Members_DefProp(m, name, prop) {
    (get := prop.get) && ObjRawSet(m.get, name, get)
    (set := prop.set) && ObjRawSet(m.set, name, set)
}
Members_DefMeth(m, name, func) {
    ObjRawSet(m.call, name, func)
}
Class_Members(cls) {
    if ObjHasKey(cls, Class_Members_Key)
        return cls[Class_Members_Key]
    ObjRawSet(cls, Class_Members_Key, m := Members_new())
    e := ObjNewEnum(cls)
    while e.Next(k, v) {
        if type(v) = "Func" {  ; Not isFunc() - don't want func NAMES, only true methods.
            Members_DefMeth(m, k, v)
        }
        else if type(v) = "Property" {
            Members_DefProp(m, k, v)
        }
        else {
            ; Inherit static variables?
        }
    }
    return m
}

Array(p*) {
    a := Object_v()
    a._ := p
    a.base := Class_ProtoMeta(Array)
    p.base := Array._Indexer
    return a
}

Object_v(p*) {
    return p
}

ForEachDelete(enumerate, deleteFrom) {
    e := ObjNewEnum(enumerate)
    while e.Next(k)
        ObjDelete(deleteFrom, k)
}

Class_DeleteMembers(cls, m) {
    ForEachDelete(m.call, cls)
    ForEachDelete(m.get, cls)
    ForEachDelete(m.set, cls)
}

class Class_Instance_Key {
}
MetaClass(cls) {
    ; Determine base class.
    cls_base := ObjGetBase(cls)  ; cls.base won't work for subclasses if MetaClass(superclass) has been called.
    if !cls_base || !ObjHasKey(cls_base, "__Class")
        throw Exception("Invalid parameter #1", -1, cls)
    if !ObjHasKey(cls_base, Class_Instance_Key) && cls_base != _ClassInitMetaFunctions
        MetaClass(cls_base)  ; Initialize base class first.
    ; Retrieve and remove internal properties.
    _instance := ObjDelete(cls, "_instance")
    _static := ObjDelete(cls, "_static")
    ; Retrieve and remove nested classes.
    _data := Object_v()
    e := ObjNewEnum(cls)
    while e.Next(k, v) {
        if type(v) == "Class"  ; Nested class (static variables should be in _static).
            ObjRawSet(_data, k, v)
    }
    ForEachDelete(_data, cls)
    ; Construct meta-object for instance prototype.
    m := _instance ? Class_Members(_instance) : Members_new()
    if !ObjHasKey(m.get, "base")
        ObjRawSet(m.get, "base", Func("Object_ReturnArg1").Bind(cls))
    if base_instance := cls_base[Class_Instance_Key] {
        Members_Inherit(m, Class_Members(base_instance))
        _instance ? _instance.base := base_instance : 0
    }
    pm := MetaObject_new(m)
    pm.base := cls  ; For type identity ('is').
    ObjRawSet(cls, Class_ProtoMeta_Key, pm)
    ObjRawSet(cls, Class_Instance_Key, _instance)
    ; Construct meta-object for class/static members.
    if _static {
        m := Class_Members(_static)
        _static.base := Class[Class_Instance_Key]
    }
    else {
        m := Members_new()
    }
    if !ObjHasKey(Class, Class_Instance_Key)
        MetaClass(Class)
    Members_Inherit(m, Class_Members(Class[Class_Instance_Key]))
    ObjRawSet(m.get, "base", Func("Object_ReturnArg1").Bind(cls_base))
    ObjRawSet(m.set, "base", Func("Object_Throw").Bind("Base class cannot be changed", -2))
    ; cm defines the interface of the class object (not instances).
    cm := MetaObject_new(m)
    cm.owner := &cls
    ; pm defines the interface of the instances, and prototype provides
    ; a way to DefineProperty()/DefineMethod() for all instances, since
    ; MyClass.DefineXxx() defines a Xxx for the class itself (static).
    proto := Object_v()
    proto._ := Object_v()
    ObjSetBase(proto, pm)
    ObjRawSet(pm, "owner", &proto)
    ObjRawSet(cls, "prototype", proto)
    ; The `new` operator skips __call and thereby calls the __new meta-function
    ; we define here.  This does some tricky work and then calls the __new method
    ; defined by the class, if any.  __init can't be handled this way since it
    ; may be the means by which MetaClass() is called, and setting it for a base
    ; class may prevent initialization of subclasses.
    ObjRawSet(cm, "__new", Func("Object__new_").Bind(pm, pm.m.call["__new"]))
    cm.base := cls_base  ; For type identity of instances ('is').
    ObjSetBase(cls, cm)
    ; Currently var initializers use ObjRawSet(), but might refer to
    ; 'this' explicitly and therefore may require this._ to be set.
    ObjRawSet(cls, "_", _data)
    if _static && ObjHasKey(_static, "__init") && type(_static.__init) == "Func" {
        _static.__init.call(_data)
    }
}


;
; Bad code! Version-dependent. Relies on undocumented stuff.
;

ObjCount(obj) {
    return NumGet(&obj+4*A_PtrSize)
}

Object(p*) {
    if p.Length() = 1 {
        return ComObject(0x4009, &(n := p[1]))[]
    }
    obj := new Object
    while p.Length() {
        value := p.Pop()
        key := p.Pop()
        obj[key] := value
    }
    return obj
}
