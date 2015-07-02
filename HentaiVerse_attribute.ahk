#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetFormat, float, 0.2
InputBox, level,, Input your level
str := level * 0.95
dex := level * 1.00
end := level * 1.05
MsgBox, 4096,, STR: %str%`n`nDEX: %dex%`nAGI: %dex%`n`nEND: %end%
