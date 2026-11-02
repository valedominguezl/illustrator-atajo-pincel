#Requires AutoHotkey v2.0
#SingleInstance Force
; Illustrator: Shift + Alt + mover el mouse (sin hacer clic) = tamaño del pincel, como Alt + clic derecho en Photoshop.
; Derecha agranda, izquierda achica. Sumando Ctrl va de a 1 pt y sumando Espacio de a 0,5 pt.
; Cambia el grosor de trazo de lo próximo que dibujes, igual que el campo «Stroke» de arriba, y el círculo de vista
; previa del propio Illustrator se actualiza solo. Por eso Alt no le llega a Illustrator: lo escondería.

;@Ahk2Exe-SetDescription Atajo de pincel para Illustrator
;@Ahk2Exe-SetName Atajo de pincel para Illustrator
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr") ; píxeles reales en los dos monitores
A_MenuMaskKey := "vkE8"
PASO := 4            ; movimiento por cada paso
FACTOR := 1.06       ; cada paso agranda/achica un 6 % (fino en tamaños chicos, rápido en grandes)
PASO_FIJO := 12      ; movimiento por cada paso con Ctrl o Espacio: más lento, para poder frenar en el valor justo
MAXIMO_STROKE := 1000 ; límite del campo Stroke
ajustando := false
movido := 0
ultimoAbsoluto := ""

A_IconTip := "Atajo de pincel: Shift + Alt en Illustrator"
A_TrayMenu.Delete()
A_TrayMenu.Add("Salir", (*) => ExitApp())

; Mientras se ajusta, Illustrator y Windows no ven estas teclas: así no cambian de herramienta ni el idioma del teclado
#HotIf ajustando
*LShift::
*RShift::
*LAlt::
*RAlt::
*LControl::
*RControl::
*Space:: return
; Alt+arrastrar mientras dibujás es de Illustrator (cerrar el trazo)
#HotIf WinActive("ahk_exe Illustrator.exe") && !GetKeyState("LButton", "P")
+LAlt::
+RAlt::
!LShift::
!RShift:: Ajustar()
#HotIf

Ajustar() {
    global ajustando, movido, ultimoAbsoluto
    if ajustando
        return
    ancho := ""
    try {
        ai := ComObjActive("Illustrator.Application")
        ancho := ai.DoJavaScript("app.documents.length ? app.activeDocument.defaultStrokeWidth : ''")
    }
    if ancho = "" {
        DevolverAlt()
        return
    }
    ancho += 0
    ajustando := true
    ; Si Alt llegó antes que Shift, se lo retira a Illustrator para que vuelva la vista previa
    SoltarTeclas(["LAlt", "RAlt"])
    CoordMode "Mouse", "Screen"
    CoordMode "ToolTip", "Screen"
    MouseGetPos &x0, &y0
    Etiqueta(ancho, 0, x0, y0)
    movido := 0, ultimoAbsoluto := "", modo := 0, seSolto := true
    EscucharMouse(true)
    BlockInput "MouseMove" ; el cursor queda quieto (antes temblaba al devolverlo a su lugar) y el movimiento se lee crudo
    while GetKeyState("Shift", "P") && GetKeyState("Alt", "P") {
        if GetKeyState("LButton", "P") { ; Shift + Alt + arrastrar es de Illustrator: se le devuelve Alt
            seSolto := false
            break
        }
        nuevoModo := GetKeyState("Control", "P") ? 1 : GetKeyState("Space", "P") ? 0.5 : 0
        if (nuevoModo != modo) {
            modo := nuevoModo, movido := 0
            Etiqueta(ancho, modo, x0, y0)
        }
        unidad := modo ? PASO_FIJO : PASO
        pasos := movido > 0 ? Floor(movido / unidad) : -Floor(-movido / unidad)
        if pasos {
            movido -= pasos * unidad
            ancho := SiguienteAncho(ancho, pasos, modo)
            Etiqueta(ancho, modo, x0, y0)
            try ai.DoJavaScript("app.activeDocument.defaultStrokeWidth = " ancho)
        }
        Sleep 5
    }
    BlockInput "MouseMoveOff"
    EscucharMouse(false)
    ToolTip
    if seSolto {
        ; Hasta soltar todo siguen bloqueadas: si no, la tecla que queda apretada le llegaría a Illustrator al repetirse
        while GetKeyState("Shift", "P") || GetKeyState("Alt", "P") || GetKeyState("Control", "P") || GetKeyState("Space", "P")
            Sleep 10
        SoltarTeclas(["LShift", "RShift", "LAlt", "RAlt"])
    } else
        DevolverAlt()
    ajustando := false
}

; modo 0: multiplica. modo 1 o 0.5: múltiplos de ese valor; si el trazo no estaba en uno, el primer paso lo lleva al más cercano.
SiguienteAncho(ancho, pasos, modo) {
    if !modo
        return Max(0.01, Min(MAXIMO_STROKE, Round(ancho * FACTOR ** pasos, 3)))
    actual := pasos > 0 ? Floor(ancho / modo + 0.0001) : Ceil(ancho / modo - 0.0001)
    return Max(modo, Min(MAXIMO_STROKE, (actual + pasos) * modo))
}

; Solo suelta lo que Illustrator cree apretado: Alt y Shift soltados a la vez son el atajo de idioma de Windows
SoltarTeclas(teclas) {
    for tecla in teclas
        if GetKeyState(tecla) {
            if InStr(tecla, "Alt")
                Send "{Blind}{vkE8}" ; para que soltar Alt no abra el menú de Illustrator
            Send "{Blind}{" tecla " up}"
        }
}

DevolverAlt() {
    if !GetKeyState("LAlt") && !GetKeyState("RAlt")
        Send "{Blind}{LAlt down}"
}

Etiqueta(ancho, modo, x, y) {
    texto := Format("Stroke {:.2f} pt  ·  {:.2f} mm", ancho, ancho * 25.4 / 72)
    if modo
        texto .= modo = 1 ? "  ·  de a 1 pt" : "  ·  de a 0,5 pt"
    ToolTip texto, x + 24, y + 24
}

; Movimiento crudo del mouse (WM_INPUT): sigue llegando aunque el cursor esté bloqueado
EscucharMouse(activar) {
    static registrado := false
    if !registrado {
        OnMessage(0xFF, MouseCrudo)
        registrado := true
    }
    dispositivo := Buffer(8 + A_PtrSize, 0)
    NumPut("ushort", 1, "ushort", 2, "uint", activar ? 0x100 : 0x1, "ptr", activar ? A_ScriptHwnd : 0, dispositivo) ; RIDEV_INPUTSINK / RIDEV_REMOVE
    DllCall("RegisterRawInputDevices", "ptr", dispositivo, "uint", 1, "uint", dispositivo.Size)
}

MouseCrudo(wParam, lParam, *) {
    global movido, ultimoAbsoluto
    cabecera := 8 + 2 * A_PtrSize
    DllCall("GetRawInputData", "ptr", lParam, "uint", 0x10000003, "ptr", 0, "uint*", &tam := 0, "uint", cabecera)
    datos := Buffer(tam, 0)
    if DllCall("GetRawInputData", "ptr", lParam, "uint", 0x10000003, "ptr", datos, "uint*", &tam, "uint", cabecera) = 0xFFFFFFFF
        return
    x := NumGet(datos, cabecera + 12, "int")
    if NumGet(datos, cabecera, "ushort") & 1 { ; tabletas: informan la posición, no el desplazamiento
        x := x * A_ScreenWidth / 65536
        if ultimoAbsoluto != ""
            movido += x - ultimoAbsoluto
        ultimoAbsoluto := x
    } else
        movido += x
}
