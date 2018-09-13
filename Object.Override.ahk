
Array(a*) {
    ; Convert the variadic arg array `a` to an Array.
    b := Array.prototype
    a.← := Object_b(b.←)
    a.base := b
    return a
}

Object(p*) {
    if ObjLength(p) & 1
        Object_throw(ValueError, "Invalid parameter count", ObjLength(p))
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
