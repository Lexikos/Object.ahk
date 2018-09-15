
OnError("ErrorDialog")

ErrorDialog(exc) {
    local
    ListLines false  ; No need to save A_ListLines: the thread will exit.
    if (trace := exc.StackTrace) != "" {
        trace := RegExReplace(trace, "m)^(?:.*\\)?", "`t")  ; Show filename only, and indent.
        RegExMatch(trace, "((?:.*\R){0,5})((?s).*)", m)
        trace := m[1], StrReplace(m[2], "`n", "`n", excess)
    } else {
        trace := "", excess := 0
        next := Exception("", n := -1)
        while (stk := next).What != n {
            next := Exception("", --n)
            ctx := (next.What < 0 ? "(main)" : next.What)
            SplitPath stk.File, filename
            if A_Index > 5
                ++excess
            else
                trace .= "`t" filename " (" stk.Line ") : " ctx "`n"
        }
    }
    if excess
        trace .= "`t... " excess " more`n"
    extype := type(exc), (extype != "Object" && extype != "Exception" || extype := "Error")
    msg := extype ": " StrReplace(exc.Message, "(" type(exc) ") ", "") "`n`n"
    if exc.Extra != ""
        msg .= "Specifically: " exc.Extra "`n`n"
    code := GetCodeContext(exc.File, exc.Line)
    
    keywords := Trim(RegExReplace(exc.Message, "\W+", " "), " ")
    
    ; Create an owner window for the MsgBox (so the Help button can work).
    ; Using A_ScriptHwnd would prevent ListLines from being usable.
    msgowner := GuiCreate()
    msgowner.Show  ; So that the MsgBox has a taskbar icon.
    renamed_buttons := false
    OnMessage 0x44, mf44 := Func("RenameButtons")
    OnMessage 0x53, mf53 := Func("Help")
    r := MsgBox(msg "`tLine#`n" code (trace!="" ? "`nCall stack:`n" trace : "")
        . "`nThe current thread will exit.", "Error - " A_ScriptName
        , "y/n/c 0x4000 Default3 Owner" msgowner.Hwnd)
    OnMessage 0x44, mf44, 0
    OnMessage 0x53, mf53, 0
    msgowner.Destroy
    
    if r = "Yes"
        Reload
    else if r = "No"
        ExitApp
    
    return true
    
    RenameButtons() {
        ListLines false
        if renamed_buttons
            return
        renamed_buttons := true
        DetectHiddenWindows true
        local hwnd := WinExist("ahk_class #32770 ahk_pid " DllCall("GetCurrentProcessId"))
        ControlSetText "&Reload", "Button1"
        ControlSetText "E&xitApp", "Button2"
        ControlSetText "&Close", "Button3"
        ControlSetText "&Help", "Button4"
    }
    
    Help() {
        local x, y, m
        ListLines false
        m := MenuCreate()
        m.Add "Search the documentation", () => Run("https://lexikos.github.io/v2/docs/search.htm?m=2&q=" keywords)
        m.Add "Search the forums", () => Run("https://autohotkey.com/boards/search.php?keywords=" keywords)
        m.Add "ListLines", () => ListLines()
        ControlGetPos x, y,,, ControlGetFocus("A")
        m.Show x, y
    }
    
    GetCodeContext(File, Line, radius:=2) {
        local
        code := ""
        Loop Read File
            if A_Index >= Line-radius
                code .= Format("{3}`t{1:03i}:  {2}`n", A_Index, A_LoopReadLine, A_Index=Line ? "--->" : "")
        until A_Index >= Line+radius
        return code
    }
}
