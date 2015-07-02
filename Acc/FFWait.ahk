#Include Acc.ahk

;F1::
	;FFWait()
	;Msgbox Loaded

; FFWait - wait for a Firefox page to finish loading
; http://www.autohotkey.com/board/topic/90620-firefox-page-load-wait/page-2#entry573049
; Requires: Acc.ahk
FFWait()
{
    WinWaitActive, ahk_class MozillaWindowClass

    ; define path to page load status push button
    ; the button's description will change when the page has finished loading
    ;button := "application.grouping2.property_page1.tool_bar2.combo_box1.push_button4"
    ; may require the path below for newer Firefox versions
    ;button := "application.tool_bar2.combo_box1.push_button4"
    ; use AccViewer to get the path
    ;button := "应用程序.工具栏3.组合框1.按下按钮3"
    button := "アプリケーション.ツール バー3.コンボ ボックス1.ボタン3"

    ; the description text that indicates page load status
    ; note that these may change - mouse over the button to see what your
    ; Firefox shows in the tooltip
    loading := "Stop loading this page"
    loaded  := "Reload current page"

    ; sleep until the description indicates page is loaded
    while description := Acc_Get("Description", button, 0, "ahk_class MozillaWindowClass") {
        if (description = loaded) {
            break
        }
        Sleep, 10
    }

    return
}
