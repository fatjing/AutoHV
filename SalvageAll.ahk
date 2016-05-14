#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include %A_ScriptDir%\Acc
#Include FFWait.ahk

End::
WinActivate, ahk_class MozillaWindowClass
global X_ := 1
global Y_ := 1
Loop, 600 {
    PixelGetColor, color, ++X_, 400
    if (0x120D5C = color)
        break
}
Loop, 400 {
    PixelGetColor, color, X_, ++Y_
    if (0x120D5C = color)
        break
}

x := X_ + 190
y := Y_ + 135
x1 := X_ + 1000
y1 := Y_ + 430
Loop {
    PixelGetColor, color, X_ + 160, Y_ + 135
    if (0x110D5C != color)
        break
    ControlClick, x%x% y%y%, A,,,, NA
    Sleep, 500
    Click %x1%, %y1%
    FFWait()
}

Esc::ExitApp
