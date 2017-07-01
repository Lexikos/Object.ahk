
class _ClassInitMetaFunctions
{
    __init() {
        ObjRawSet(this, "_", MetaClass(this))
        cm := ObjGetBase(this.prototype)
        if f := cm.m.call["__init"]
            f.call(this)
    }
    __get(p*) {
        ObjRawSet(this, "_", MetaClass(this))
        return this[p*]
    }
    __set(p*) {
        ObjRawSet(this, "_", MetaClass(this))
        v := p.Pop()
        return this[p*] := v
    }
    __call(p*) {
        ObjRawSet(this, "_", MetaClass(this))
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
        is(type) {
            return this is type
        }
        
        HasProperty(name) {
            cm := ObjGetBase(this)
            return isObject(cm.m.get[name] || cm.m.set[name])
                || ObjHasKey(this._, name)
                ; || ObjHasKey(this, name)
        }
        HasMethod(name) {
            cm := ObjGetBase(this)
            return isObject(cm.m.call[name])
        }
        
        DefineProperty(name, prop) {
            if !isObject(prop) || !(prop.get || prop.set)
                throw Exception("Invalid parameter #2", -2, prop)
            cm := Own_Meta(this)
            Class_Members_DefProp(cm.m, name, prop)
        }
        
        DefineMethod(name, func) {
            if !isObject(func)
                throw Exception("Invalid parameter #2", -2, func)
            cm := Own_Meta(this)
            Class_Members_DefMeth(cm.m, name, func)
        }
        
        ; Standard object methods
        Delete(p*) {
            return ObjDelete(this._, p*)
        }
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
    static _ := ("".base.is := Func("Value__call"), 0)
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
                return this._['length'] || ObjLength(this._)
            }
            set {
                if !(value is 'integer') || value < 0
                    throw Exception("Invalid value", -1, value)
                n := ObjLength(this._)
                if value < n
                    this.Delete(value + 1, n)
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
            return this.n <= this._.Length()
        }
        Next2(ByRef a, ByRef b) {
            return this.e.Next(a, b)
        }
    }
    
    class _Indexer {
        __get(index, p*) {
            if index <= 0 && index is 'integer' {
                len := this.HasKey('length') ? this.length : this.Length()
                return this[len + index + 1, p*]
            }
        }
        __set(index, p*) {
            if index <= 0 && index is 'integer' && p.Length() {
                len := this.HasKey('length') ? this.length : this.Length()
                value := p.Pop()
                return this[len + index + 1, p*] := value
            }
        }
    }
}

Object__new_(cm, f, this) {
    self := Object_v()
    ; This reuses the original object for data storage, since it already
    ; contains the ad hoc properties which were created in __init.
    ; FIXME: It's probably better to have property-assignment semantics,
    ;  not direct-to-data (i.e. property setters should be called).
    self._ := this
    self.base := cm
    ObjSetBase(this, "")
    (f) && f.call(self)
    return self
}
Object__init_(f, this) {
    f.call(this)
}
Object__get_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    return this._[k, p*]
}
Object__set_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    value := p.Pop()
    return this._[k, p*] := value
}
Object__call_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    throw Exception("No such method", -2, k)
}

class Class_Meta_Key {
}
Class_Meta(cls) {
    if !ObjHasKey(cls, Class_Meta_Key)
        MetaClass(cls)
    return cls[Class_Meta_Key]
}

Class_Meta_new(m) {
    cm := Object_v()
    cm.__get := Func("Object__get_").Bind(m.get)
    cm.__set := Func("Object__set_").Bind(m.set)
    cm.__call := Func("Object__call_").Bind(m.call)
    cm.m := m
    return cm
}

Own_Meta(this) {
    cm := ObjGetBase(this)  ; It is assumed that 'this' is a properly constructed Object, with a meta-object.
    if cm.owner == &this
        return cm
    ; else: cm is shared.
    m := Class_Members_new()
    tm := Class_Meta_new(m)
    tm.owner := &this
    Class_Members_SetBase(m, cm)
    ObjSetBase(this, tm)
    return tm
}

Object_ReturnArg1(arg1) {
    return arg1
}

Object_Throw(message, what) {
    throw Exception(message, what)
}

Object_SetBase(this, newbase) {
    if newbase is Object && ObjHasKey(newbase, "__Class") || newbase = Object
        ObjSetBase(this, Class_Meta(newbase))
    else
        ObjSetBase(this, newbase)
    return newbase
}

class Class_Members_Key {
}
Class_Members_new() {
    m := Object_v()
    m.get := Object_v()
    m.set := Object_v()
    m.call := Object_v()
    ObjRawSet(m.get, "base", "")
    ObjRawSet(m.set, "base", "")
    ObjRawSet(m.call, "base", "")
    return m
}
Class_Members_SetBase(m, b) {
    bm := Class_Members(b)
    ObjSetBase(m.get, bm.get)
    ObjSetBase(m.set, bm.set)
    ObjSetBase(m.call, bm.call)
}
Class_Members_DefProp(m, name, prop) {
    (get := prop.get) && (m.get[name] := get)
    (set := prop.set) && (m.set[name] := set)
}
Class_Members_DefMeth(m, name, func) {
    m.call[name] := func
}
Class_Members(cls) {
    if ObjHasKey(cls, Class_Members_Key)
        return cls[Class_Members_Key]
    ObjRawSet(cls, Class_Members_Key, m := Class_Members_new())
    e := ObjNewEnum(cls)
    while e.Next(k, v) {
        if type(v) = "Func" {  ; Not isFunc() - don't want func NAMES, only true methods.
            Class_Members_DefMeth(m, k, v)
        }
        else if type(v) = "Property" {
            Class_Members_DefProp(m, k, v)
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
    a.base := Class_Meta(Array)
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

class MetaClass_Instance_Key {
}
MetaClass(cls) {
    ; Determine base class.
    cls_base := ObjGetBase(cls)  ; cls.base won't work for subclasses if MetaClass(superclass) has been called.
    if !(cls_base is _ClassInitMetaFunctions) ; i.e. derived from, not the _Class itself.
        cls_base := ""
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
    m := _instance ? Class_Members(_instance) : Class_Members_new()
    if !m.get["base"]
        m.get["base"] := Func("Object_ReturnArg1").Bind(cls)
    if !cls_base && !m.set["base"]
        m.set["base"] := Func("Object_SetBase")
    if cls_base && cls_base[MetaClass_Instance_Key]
        Class_Members_SetBase(m, cls_base[MetaClass_Instance_Key])
    cm := Class_Meta_new(m)
    cm.base := cls  ; For type identity ('is').
    ObjRawSet(cls, Class_Meta_Key, cm)
    ObjRawSet(cls, MetaClass_Instance_Key, _instance)
    ; Construct meta-object for class/static members.
    if _static {
        m := Class_Members(_static)
        _static.base := Class[MetaClass_Instance_Key]
    }
    else {
        m := Class_Members_new()
    }
    if !ObjHasKey(Class, MetaClass_Instance_Key)
        MetaClass(Class)
    Class_Members_SetBase(m, Class[MetaClass_Instance_Key])
    m.get["base"] := Func("Object_ReturnArg1").Bind(cls_base)
    m.set["base"] := Func("Object_Throw").Bind("Base class cannot be changed", -2)
    ; mcm defines the interface of the class object (not instances).
    mcm := Class_Meta_new(m)
    mcm.owner := &cls
    ; cm defines the interface of the instances, and prototype provides
    ; a way to DefineProperty()/DefineMethod() for all instances, since
    ; MyClass.DefineXxx() defines a Xxx for the class itself (static).
    proto := Object_v()
    proto._ := Object_v()
    ObjSetBase(proto, cm)
    ObjRawSet(cm, "owner", &proto)
    ObjRawSet(cls, "prototype", proto)
    ; __new and __init must be set here because __call isn't called for them,
    ; and we need to do special stuff anyway.  These are called with 'this' set
    ; to the new instance, and shouldn't be callable by the script since __call
    ; would be called in those cases.
    ; mcm.__new := Func("Object__new_").Bind(cm, cm.m.call["__new"])  ; This is called on class.base because the instance won't have a meta-object until after this is called.
    ; if cm.m.call["__init"]
        ; mcm.__init := Func("Object__init_").Bind(cm.m.call["__init"])
    ; They're set on the class itself rather than mcm because base.__init()
    ; would otherwise cause infinite recursion.
    ObjRawSet(cls, "__new", Func("Object__new_").Bind(cm, cm.m.call["__new"]))
    if cm.m.call["__init"]
        ObjRawSet(cls, "__init", Func("Object__init_").Bind(cm.m.call["__init"]))
    mcm.base := cls_base  ; For type identity of instances ('is').
    ObjSetBase(cls, mcm)
    ; Currently var initializers use ObjRawSet(), but might refer to
    ; 'this' explicitly and therefore may require this._ to be set.
    ObjRawSet(cls, "_", _data)
    if _static && _static.__init {
        _static.__init.call(_data)
    }
    return _data  ; Caller may also store this in cls._ (redundantly).
}


;
; Bad code! Version-dependent. Relies on undocumented stuff.
;

ObjGetBase(obj) {
    try
        ObjGetCapacity(obj) ; Type-check.
    catch
        throw Exception("Invalid parameter #1", -1, obj)
    if thebase := NumGet(&obj + 2*A_PtrSize)
        return Object(thebase)
}

ObjSetBase(obj, newbase) {
    try
        ObjGetCapacity(obj) ; Type-check.
    catch
        throw Exception("Invalid parameter #1", -1, obj)
    if newbase {
        if !isObject(newbase)
            throw Exception("Invalid parameter #2", -1, newbase)
        ObjAddRef(&newbase)
        newbase := &newbase
    }
    oldbase := NumGet(&obj, 2*A_PtrSize)
    NumPut(newbase, &obj, 2*A_PtrSize)
    if oldbase
        ObjRelease(oldbase)
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
