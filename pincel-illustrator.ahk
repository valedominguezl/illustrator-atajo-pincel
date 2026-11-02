#Requires AutoHotkey v2.0
#SingleInstance Force
; Illustrator: Shift + Alt + mover el mouse (sin hacer clic) = tamaño del pincel, como Alt + clic derecho en Photoshop.
; Derecha agranda, izquierda achica. Sumando Ctrl va de a 1 y sumando Espacio de a 0,5, en la unidad del Stroke (pt, mm…).
; Apretando M durante el gesto, Illustrator pasa el Stroke de pt a mm y viceversa.
; Cambia el grosor de trazo de lo próximo que dibujes, igual que el campo «Stroke» de arriba, y el círculo de vista
; previa del propio Illustrator se actualiza solo. Por eso Alt no le llega a Illustrator: lo escondería.

;@Ahk2Exe-SetDescription Atajo de pincel para Illustrator
;@Ahk2Exe-SetName Atajo de pincel para Illustrator
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr") ; píxeles reales en los dos monitores
A_MenuMaskKey := "vkE8"
PASO := 24           ; movimiento por cada paso
FACTOR := 1.03       ; cada paso agranda/achica un 3 % (fino en tamaños chicos, rápido en grandes)
PASO_FIJO := 120     ; movimiento por cada paso con Ctrl o Espacio: más lento, para poder frenar en el valor justo
MAXIMO_STROKE := 400 ; tope del Stroke, en pt
; Preferencia strokeUnits de Illustrator: puntos por unidad y nombre
UNIDADES := Map(0, [72, "in"], 1, [72 / 25.4, "mm"], 2, [1, "pt"], 3, [12, "pc"], 4, [72 / 2.54, "cm"], 5, [72 / 101.6, "Q"], 6, [1, "px"])
; Diagnóstico: solo registra si ya existe este archivo, que el instalador no crea
REGISTRO := A_Temp "\pincel-atajo.log"
ajustando := false
cambiarUnidad := false
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
*m:: {
    global cambiarUnidad := true
}
; Solo en la ventana principal: con un diálogo abierto, Illustrator no responde hasta cerrarlo.
; Alt+arrastrar mientras dibujás es de Illustrator (cerrar el trazo)
#HotIf WinActive("ahk_class illustrator ahk_exe Illustrator.exe") && !GetKeyState("LButton", "P")
+LAlt::
+RAlt::
!LShift::
!RShift:: Ajustar()
#HotIf

Ajustar() {
    global ajustando, movido, ultimoAbsoluto, cambiarUnidad
    if ajustando
        return
    Anotar("inicio " A_ThisHotkey " " TeclasLogicas())
    datos := []
    if IllustratorResponde() {
        try {
            ai := ComObjActive("Illustrator.Application")
            datos := StrSplit(ai.DoJavaScript("app.documents.length ? app.activeDocument.defaultStrokeWidth + '|' + app.preferences.getIntegerPreference('strokeUnits') : ''"), "|")
        } catch as e
            Anotar("error al leer: " e.Message)
    } else
        Anotar("Illustrator no responde")
    if datos.Length < 2 {
        DevolverAlt()
        return
    }
    ancho := datos[1] + 0
    unidad := UNIDADES.Has(datos[2] + 0) ? UNIDADES[datos[2] + 0] : UNIDADES[2]
    cambiarUnidad := false
    ajustando := true
    ; Si Alt llegó antes que Shift, se lo retira a Illustrator para que vuelva la vista previa
    SoltarTeclas(["LAlt", "RAlt"])
    CoordMode "Mouse", "Screen"
    CoordMode "ToolTip", "Screen"
    MouseGetPos &x0, &y0
    Etiqueta(ancho, 0, unidad, x0, y0)
    movido := 0, ultimoAbsoluto := "", modo := 0, seSolto := true
    EscucharMouse(true)
    BlockInput "MouseMove" ; el cursor queda quieto (antes temblaba al devolverlo a su lugar) y el movimiento se lee crudo
    while GetKeyState("Shift", "P") && GetKeyState("Alt", "P") {
        if GetKeyState("LButton", "P") { ; Shift + Alt + arrastrar es de Illustrator: se le devuelve Alt
            seSolto := false
            break
        }
        if cambiarUnidad {
            cambiarUnidad := false
            nueva := unidad[2] = "mm" ? 2 : 1
            if IllustratorResponde()
                try {
                    ai.DoJavaScript("app.preferences.setIntegerPreference('strokeUnits', " nueva ")")
                    unidad := UNIDADES[nueva]
                    movido := 0
                    Etiqueta(ancho, modo, unidad, x0, y0)
                }
        }
        nuevoModo := GetKeyState("Control", "P") ? 1 : GetKeyState("Space", "P") ? 0.5 : 0
        if (nuevoModo != modo) {
            modo := nuevoModo, movido := 0
            Etiqueta(ancho, modo, unidad, x0, y0)
        }
        porPaso := modo ? PASO_FIJO : PASO
        pasos := movido > 0 ? Floor(movido / porPaso) : -Floor(-movido / porPaso)
        if pasos {
            movido -= pasos * porPaso
            ancho := SiguienteAncho(ancho, pasos, modo, unidad[1])
            Etiqueta(ancho, modo, unidad, x0, y0)
            if IllustratorResponde()
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
        SoltarTeclas()
    } else
        DevolverAlt()
    ajustando := false
    Anotar("fin soltó=" seSolto " " TeclasLogicas())
}

; ancho en pt. modo 0: multiplica y redondea en la unidad del Stroke. modo 1 o 0.5: múltiplos de ese valor en esa unidad;
; si el trazo no estaba en uno, el primer paso lo lleva al más cercano.
SiguienteAncho(ancho, pasos, modo, ptPorUnidad) {
    valor := ancho / ptPorUnidad
    if modo {
        actual := pasos > 0 ? Floor(valor / modo + 0.0001) : Ceil(valor / modo - 0.0001)
        return Min(MAXIMO_STROKE, Max(modo, (actual + pasos) * modo) * ptPorUnidad)
    }
    nuevo := Round(valor * FACTOR ** pasos, 2)
    if nuevo = Round(valor, 2) ; en valores chicos, el 3 % no llega a mover el redondeo
        nuevo += pasos > 0 ? 0.01 : -0.01
    return Min(MAXIMO_STROKE, Max(0.01, nuevo) * ptPorUnidad)
}

; Solo suelta lo que el sistema cree apretado: Alt y Shift soltados a la vez son el atajo de idioma de Windows
SoltarTeclas(teclas := ["LShift", "RShift", "LAlt", "RAlt", "LControl", "RControl", "Space"]) {
    for tecla in teclas
        if GetKeyState(tecla) {
            if InStr(tecla, "Alt")
                Send "{Blind}{vkE8}" ; para que soltar Alt no abra el menú de Illustrator
            Send "{Blind}{" tecla " up}"
        }
}

; Illustrator recibe Alt, pero su soltado físico no le va a llegar porque el atajo se quedó con la pulsación:
; hay que avisarle a mano, o queda trabado para todo Windows
DevolverAlt() {
    if !GetKeyState("LAlt") && !GetKeyState("RAlt")
        Send "{Blind}{LAlt down}"
    SetTimer SoltarAlTerminar, 50
}

SoltarAlTerminar() {
    for tecla in ["Shift", "Alt", "Control", "Space"]
        if GetKeyState(tecla, "P")
            return
    SetTimer SoltarAlTerminar, 0
    SoltarTeclas()
    Anotar("destrabado " TeclasLogicas())
}

IllustratorResponde() {
    respondio := DllCall("SendMessageTimeout", "ptr", WinExist("ahk_class illustrator ahk_exe Illustrator.exe"), "uint", 0, "ptr", 0, "ptr", 0, "uint", 0x2, "uint", 200, "ptr*", &r := 0, "ptr") ; WM_NULL, SMTO_ABORTIFHUNG
    return respondio != 0
}

TeclasLogicas() {
    s := ""
    for tecla in ["LShift", "RShift", "LAlt", "RAlt", "LControl", "RControl", "Space"]
        if GetKeyState(tecla)
            s .= tecla " "
    return "abajo: [" s "]"
}

Anotar(texto) {
    if FileExist(REGISTRO)
        try FileAppend A_Now " " texto "`n", REGISTRO, "UTF-8"
}

Etiqueta(ancho, modo, unidad, x, y) {
    texto := Format("Stroke {:.2f} {}", ancho / unidad[1], unidad[2])
    if unidad[2] != "pt"
        texto .= Format("  ·  {:.2f} pt", ancho)
    if modo
        texto .= (modo = 1 ? "  ·  de a 1 " : "  ·  de a 0,5 ") unidad[2]
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
