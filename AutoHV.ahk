#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include %A_ScriptDir%\Acc
;#Include %A_ScriptDir%\UIA_Interface
#Include FFWait.ahk

wait()
{
    FFWait()

    global mob
    static newRound := false

    ; popup at round ending and riddle master and page loading failure
    PixelGetColor, color, X_ + 740, Y_ + 179    ; a point on the border of the popup window, inside the pony picture
    if (0xDFEBED = color) {    ; no popup
        if newRound {
            newRound := false
            mob := true
            getBoss()
        }
    }
    else if (0xB9B8CF = color) {    ; popup
        PixelGetColor, color1, X_ + 840, Y_ + 27    ; bottom line of menu bar
        if (0xDFEBED != color1) {
            enterArena()
        }
        else {
            Sleep, 100
            SendInput, {Enter}
            newRound := true
            FFWait()
        }
    }
    else if (0xFBFBFB = color) {    ; page loading failure
        SendInput, {F5}
        Sleep, 500
        SendInput, {Enter}
        FFWait()
    }
    else {    ; riddle master
        Sleep, 2000
        x := X_ + 653
        y := Y_ + 34
        ControlClick, x%x% y%y%, A,,,, NA
        Random, rand, 1, 3
        if (1 = rand)
            SendInput, a
        else if (2 = rand)
            SendInput, b
        else
            SendInput, c
        Sleep, 500
        SendInput, {Enter}
        Click
        FFWait()
    }

    return
}

; enter next arena automatically after clearing one arena
enterArena()
{
    global running
    global arena
    static page2 := true

    if not arena {
        running := false
        return
    }

    Sleep, 500
    SendInput, {Enter}
    FFwait()

    ; restoratives
    x := X_ + 70
    y := Y_ + 250
    ControlClick, x%x% y%y%, A,,,, NA
    Sleep, 500
    x := X_ + 70
    y := Y_ + 390    ; Recover All
    ControlClick, x%x% y%y%, A,,,, NA
    FFwait()

    if page2 {
        x := X_ + 770
        y := Y_ + 60
        ControlClick, x%x% y%y%, A,,,, NA    ; click page 2
        FFwait()
        x := X_ + 1135
        y := Y_ + 120 + 7*36
        PixelGetColor, color1, x, y    ; start button
    }
    else {
        x := X_ + 1135
        y := Y_ + 120 + 10*36
        PixelGetColor, color1, x, y    ; start button
    }

    while (0xDFEBED != color1) {
        if (0xADB6B8 != color1) {
            ControlClick, x%x% y%y%, A,,,, NA
            Sleep, 500
            SendInput, {Enter}
            return
        }
        y -= 36
        PixelGetColor, color1, x, y    ; start button
        if (page2 and 0xDFEBED = color1) {
            page2 := false
            x := X_ + 610
            y := Y_ + 60
            ControlClick, x%x% y%y%, A,,,, NA    ; click page 1
            FFwait()
            x := X_ + 1135
            y := Y_ + 120 + 10*36
            PixelGetColor, color1, x, y    ; start button
        }
    }

    running := false
    return
}

; use n-th item
useItem(n)
{
    SendInput, e
    Sleep, 500

    x := X_ + 198
    y := Y_ + 229 + 23*(n-1)
    PixelGetColor, color, x, y
    if (0x110D5C = color) {    ; item is available
        ControlClick, x%x% y%y%, A,,,, NA
        Click
        wait()
        return true
    }
    else
        return false
}

; check hp gauge color for low hp and recover it by casting cure spell or using health potion
recoverHP()
{
    PixelGetColor, color, X_ + 18 + 63, Y_ + 147    ; hp gauge 55%, 114*0.55=62.7
    if (0x000000 = color) {
        x := X_ + 175 + 5*37
        y := Y_ + 89
        PixelGetColor, color, x, y    ; 6th spell icon on the quickbar
        if (0x15282C = color) {    ; check cool down for Cure
            SendInput, !6
            wait()
            return true
        }
        else {
            x := X_ + 175 + 12*37
            y := Y_ + 89
            PixelGetColor, color, x, y    ; 13th spell icon on the quickbar
            if (0x15282C = color) {    ; check cool down for Full-Cure
                ControlClick, x%x% y%y%, A,,,, NA
                Click
                wait()
                return true
            }
            else {
                return useItem(2)    ; use health potion
            }
        }
    }

    return false
}

; check mp gauge color and use mana potion on low mp
replenishMP()
{
    global mob
    global encounter
    PixelGetColor, color, X_ + 18 + 23, Y_ + 147 + 41    ; mp gauge 20%, 114*0.2=22.8
    if (0x000000 = color) {
        if useItem(4)    ; use mana potion
            return true

        if (not mob and not encounter)
            normalAttack(1)
    }

    return false
}

; use powerup gem
useGem()
{
    ;SendInput, e
    ;Sleep, 500
    ;PixelGetColor, color, X_ + 198, Y_ + 206    ; gem item entry
    wait()
    PixelGetColor, color, X_ + 783, Y_ + 59    ; gem icon
    if (0xDFEBED != color) {
        SendInput, g
        wait()
        return true
    }
    else {
        ;SendInput, e
        return false
    }
}

; trigger spirit stance
toggleSpirit()
{
    PixelGetColor, color, X_ + 18 + 86, Y_ + 147 + 41*2    ; spirit gauge 75%, 114*0.75=85.5
    PixelGetColor, color1, X_ + 18 + 114, Y_ + 147 + 41*3    ; overcharge gauge 100%
    if (0x000000 != color1 and 0x000000 != color) {
        SendInput, s
        wait()
        return true
    }
    else {
        return false
    }
}

; get the n-th non-boss (if possible) live monster or first monster with coalesced mana effect
getTargetMonster(n)
{
    global boss
    global arrayBoss
    global mob
    foo := 1
    number := 0
    mob_iterator := -1
    boss_iterator := -1
    x1 := X_ + 1006
    x2 := x1 + 5*(30 + 3) - 4
    Loop {
        PixelGetColor, color, X_ + 893, Y_ + 71 + (foo-1)*58    ; monster hp gauge
        if (0x9DA5A6 != color) {    ; monster's hp is not of dead color
            if (0xDFEBED = color) {    ; out of range, end loop
                if (-1 = mob_iterator) {
                    mob := false
                    return 10 = boss_iterator ? 0 : boss_iterator
                }
                else {
                    return 10 = mob_iterator ? 0 : mob_iterator
                }
            }
            else {
                if (0 != boss) {
                    Loop %boss% {
                        if (foo = arrayBoss[A_Index]) {
                            boss_iterator := foo
                            break
                        }
                    }
                }
                if (boss_iterator != foo) {
                    ; check coalesced mana effect
                    y1 := Y_ + 67 + (foo-1)*58
                    y2 := y1 + 32 - 1
                    ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\coalescemana.png
                    if (0 = ErrorLevel)
                        return 10 = foo ? 0 : foo

                    ++number
                    if (number < n)
                        mob_iterator := foo
                    else
                        return 10 = foo ? 0 : foo
                }
            }
        }
        ++foo
    }
}

; get live monster and check whether it's a boss, store boss(es) in the arrayBoss
getBoss()
{
    global arrayBoss
    global boss
    foo := 1
    bar := 1
    boss := 0
    Loop % arrayBoss.MaxIndex()
        arrayBoss[A_Index] := -1

    Loop {
        PixelGetColor, color, X_ + 893, Y_ + 71 + (foo-1)*58    ; monster hp gauge
        if (0x9DA5A6 != color) {    ; monster's hp is not of dead color
            if (0xDFEBED = color) {    ; out of range
                break
            }
            else {
                PixelGetColor, color, X_ + 848, Y_ + 71 + (foo-1)*58    ; monster number region
                if (0xDFEBED != color) {
                    arrayBoss[bar] := foo
                    ++bar
                }
            }
        }
        ++foo
    }

    Loop % arrayBoss.MaxIndex() {
        if (-1 != arrayBoss[A_Index]) {
            ++boss
        }
    }

    return
}

; perform a normal attack on the n-th monster
normalAttack(n)
{
    foo := getTargetMonster(n)
    SendInput, %foo%
    wait()
    return
}

; cast offensive / deprecating spell on the n-th monster
offensiveSpell(shortcut, n)
{
    foo := getTargetMonster(n)
    SendInput, !%shortcut%
    SendInput, %foo%
    wait()
    return
}

; check channeling
channeling()
{
    x1 := X_ + 165
    y1 := Y_ + 11
    x2 := x1 + 7*(30 + 3) - 4
    y2 := y1 + 32 - 1
    ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\channeling.png
    if (0 = ErrorLevel)
        return true
    else
        return false
}

; grind deprecating magic proficiency
grindDeprecatingProf()
{
    offensiveSpell(0, 1)
    offensiveSpell(9, 1)
    ;recoverHP()
    ;offensiveSpell(0, 1)
    ;offensiveSpell(8, 1)
    return
}

; grind supportive magic proficiency
grindSupportiveProf()
{
    SendInput, !6
    wait()
    SendInput, !1
    wait()
    SendInput, !1
    wait()
    return
}

; grind weapon proficiency
grindWeaponProf()
{
    rebuff()
    normalAttack(1)
    return
}

; grind elemental proficiency
grindElementalProf()
{
    rebuff()
    recoverHP()

    global encounter
    global boss
    global mob
    if (0 != boss) or encounter {
        debuff()
        recoverHP()
    }

    channeling := channeling()
    if (channeling) {
        if rebuff()
            return
    }

    if (0 != boss or encounter or channeling) {
        x := X_ + 175 + 14*37
        y := Y_ + 89
        PixelGetColor, color, x, y    ; 15th spell icon on the quickbar
        if (0xF8D8A8 = color) {    ; check cool down for Wrath of Thor
            foo := getTargetMonster(1)
            ControlClick, x%x% y%y%, A,,,, NA
            SendInput, %foo%
            Click
            wait()
            return
        }
    }

    x := X_ + 175 + 15*37
    y := Y_ + 89
    PixelGetColor, color, x, y    ; 16th spell icon on the quickbar
    if (0xD8C8C8 = color) {    ; check cool down for Chained Lightning
        foo := getTargetMonster(4)
        ControlClick, x%x% y%y%, A,,,, NA
        SendInput, %foo%
        Click
        wait()
    }
    else {
        offensiveSpell(7, 3)
    }

    return
}

; add buffs
rebuff()
{
    global encounter
    channeling := channeling()
    PixelGetColor, color, X_ + 370, Y_ + 19    ; 7th icon of the status effect bar
    if (0xDFEBED = color or channeling) {
        x1 := X_ + 165
        y1 := Y_ + 11
        x2 := x1 + 9*(30 + 3) - 4
        y2 := y1 + 32 - 1

        if channeling
            x2 := x1 + 10*(30 + 3) - 4

        if not encounter {
            ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\manapot.png
            if (0 != ErrorLevel) {
                useItem(3)    ; use mana draught
            }
            ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\healthpot.png
            if (0 != ErrorLevel) {
                useItem(1)    ; use health draught
            }
        }

        ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\haste.png
        if (0 != ErrorLevel) {
            SendInput, !1
            wait()
            if not encounter
                return true
            recoverHP()
        }

        ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\protection.png
        if (0 != ErrorLevel) {
            SendInput, !2
            wait()
            if not encounter
                return true
            recoverHP()
        }

        PixelGetColor, color, X_ + 18 + 57, Y_ + 147 + 41*2    ; spirit gauge 50%, 114*0.5=57
        if (0x000000 != color) {
            ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\sparklife.png
            if (0 != ErrorLevel) {
                SendInput, !3
                wait()
                if not encounter
                    return true
                recoverHP()
            }
        }

        ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\shadowveil.png
        if (0 != ErrorLevel) {
            SendInput, !4
            wait()
            if not encounter
                return true
            recoverHP()
        }

        if (channeling or encounter) {
            ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\regen.png
            if (0 != ErrorLevel) {
                SendInput, !5
                wait()
                if not encounter
                    return true
                recoverHP()
            }
        }

        if (encounter) {
            x := X_ + 175 + 13*37
            y := Y_ + 89
            PixelGetColor, color, x, y    ; 14th spell icon on the quickbar
            if (0xF8E8B8 = color) {    ; check cool down for absorb
                ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\absorb.png
                if (0 != ErrorLevel) {
                    ControlClick, x%x% y%y%, A,,,, NA
                    Click
                    wait()
                    ;recoverHP()
                }
            }
        }

        if (channeling) {
            ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\arcanemeditation.png
            if (0 != ErrorLevel) {
                x := X_ + 175 + 11*37
                y := Y_ + 89
                ControlClick, x%x% y%y%, A,,,, NA
                Click
                wait()
                return true
            }
        }
    }
    return false
}

; debuff boss or mob, for mob, only when in encounter mode
debuff()
{
    global encounter
    global boss
    global arrayBoss

    if encounter {
        count := 3
    }
    else {
        getBoss()
        count := boss
    }

    Loop, %count% {
        if encounter
            foo := getTargetMonster((4-A_Index) * 3)
        else
            foo := arrayBoss[A_index]

        x := X_ + 1150
        y := Y_ + 80 + (foo-1)*58
        PixelGetColor, color, x, y    ; 5th status effect icon of target monster
        if (0xDFEBED = color) {
            x1 := X_ + 1006
            y1 := Y_ + 67 + (foo-1)*58
            x2 := x1 + 5*(30 + 3) - 4
            y2 := y1 + 32 - 1

            x3 := X_ + 175 + 10*37
            y3 := Y_ + 89
            PixelGetColor, color, x3, y3    ; 11th spell icon on the quickbar
            if (0x4D506F = color) {    ; check cool down for Silence
                ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\silence.png
                if (0 != ErrorLevel) {
                    ControlClick, x%x3% y%y3%, A,,,, NA
                    if (10 = foo)
                        foo := 0
                    SendInput, %foo%
                    Click
                    wait()
                    return
                }
            }
            else if encounter
                return

            if not encounter {
                ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\imperil.png
                if (0 != ErrorLevel) {
                    SendInput, !9
                    if (10 = foo)
                        foo := 0
                    SendInput, %foo%
                    wait()
                    return
                }

                ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\weaken.png
                if (0 != ErrorLevel) {
                    SendInput, !0
                    if (10 = foo)
                        foo := 0
                    SendInput, %foo%
                    wait()
                    return
                }

                ImageSearch, , , x1, y1, x2, y2, *w30 *h32 %A_ScriptDir%\HentaiVerse_Image\slow.png
                if (0 != ErrorLevel) {
                    SendInput, !8
                    if (10 = foo)
                        foo := 0
                    SendInput, %foo%
                    wait()
                    return
                }
            }
        }
    }
    return
}

flow(option)
{
    if (option = 1)
        grindElementalProf()
    else if (option = 2)
        grindWeaponProf()
    else if (option = 3)
        grindSupportiveProf()
    else
        grindDeprecatingProf()

    useGem()
    recoverHP()
    replenishMP()

    ;toggleSpirit()
}


running := false

#MaxThreadsPerHotkey 3
Home::
#MaxThreadsPerHotkey 1
number := 4
Gosub main
return

#MaxThreadsPerHotkey 3
PgUp::
#MaxThreadsPerHotkey 1
number := 3
Gosub main
return

#MaxThreadsPerHotkey 3
PgDn::
#MaxThreadsPerHotkey 1
number := 2
Gosub main
return

#MaxThreadsPerHotkey 3
End::
#MaxThreadsPerHotkey 1
number := 1
Gosub main
return

main:
    if running {
        running := false
        return
    }
    running := true

    WinActivate, ahk_class MozillaWindowClass
    ; set up the coordinates of the top-left corner of the .stuffbox <div>
    ; mine is 6, 101
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
    MouseMove, X_ + 740, Y_ + 600

    ; check battle mode
    SendInput, !d
    Sleep, 500
    SendInput, ^c
    Sleep, 20
    Click
    urlBattle := "&ss=ar"
    IfInString, clipboard, %urlBattle%
    {
        arena := true
        encounter := false
    }
    else {
        urlBattle := "encounter"
        IfInString, clipboard, %urlBattle%
        {
            arena := false
            encounter := true
        }
        else {
            arena := false
            encounter := false
        }
    }

    mob := true
    boss := 0
    arrayBoss := [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
    getBoss()

    Loop {
        if not running
            break

        flow(number)
    }
    running := false
    return

Esc::Reload
