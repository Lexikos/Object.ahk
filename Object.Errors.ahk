 
Object_throw(extype, p*) {
    throw extype.new(p*)
}

class Exception extends Object
{
    class _instance
    {
        __new(msg:="", extra:="", skip_frames:=0) {
            while (stk := Exception("", -A_Index-1)).What != -A_Index-1
                if !(stk.File ~= "\\Object(?:\.\w+)?\.ahk")
                    if skip_frames-- <= 0
                        break
            ; The built-in error dialog requires that these be set raw.
            ObjRawSet this, "Message", '(' type(this) ') ' msg
            ObjRawSet this, "Extra", Object_String(extra)
            ObjRawSet this, "File", stk.File
            ObjRawSet this, "Line", stk.Line
            
            this.StackTrace := Exception.StackTrace()
        }
    }
    
    class _static
    {
        StackTrace() {
            trace := ""
            next := Exception("", n := -1)
            while (stk := next).What != n {
                next := Exception("", --n)
                if (stk.File ~= "\\Object(?:\.\w+)?\.ahk")
                    continue
                ctx := (next.What < 0 ? "(main)" : next.What)
                trace .= stk.File " (" stk.Line ") : " ctx "`n"
            }
            return trace
        }
    }
}

class TypeError extends Exception
{
    class _instance
    {
        __new(p*) {
            base.__new(p*)
            if ObjHasKey(p, 2) && !isObject(p[2])
                this.Extra .= ' (' type(p[2]) ')'
        }
    }
}

class MemberError extends Exception
{
}

class PropertyError extends MemberError
{
}

class MethodError extends MemberError
{
}

class ValueError extends Exception
{
}

class IndexError extends ValueError
{
}

_throw_Immutable(this) {
    Object_throw(TypeError, "This object is immutable.", this)
}
