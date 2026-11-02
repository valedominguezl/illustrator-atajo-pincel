#Requires AutoHotkey v2.0
#SingleInstance Force
; Illustrator: Shift + Alt + mover el mouse (sin hacer clic) = tamaño del pincel, como Alt + clic derecho en Photoshop.
; Derecha agranda, izquierda achica. Sumando Ctrl va de a 1 y sumando Bloq Mayús de a 0,5, en la unidad del Stroke (pt, mm…).
; Apretando A durante el gesto, Illustrator pasa el Stroke de pt a mm y viceversa. Esas teclas y la sensibilidad se
; cambian en los ajustes (doble clic en el ícono de la bandeja) y se guardan en pincel.ini, junto al .exe.
; Cambia el grosor de trazo de lo próximo que dibujes, igual que el campo «Stroke» de arriba, y el círculo de vista
; previa del propio Illustrator se actualiza solo. Por eso Alt no le llega a Illustrator: lo escondería.

;@Ahk2Exe-SetDescription Atajo de pincel para Illustrator
;@Ahk2Exe-SetName Atajo de pincel para Illustrator
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr") ; píxeles reales en los dos monitores
A_MenuMaskKey := "vkE8"
BASE_LIBRE := 24     ; movimiento por cada paso con sensibilidad 50
BASE_FIJO := 240     ; lo mismo con los pasos de 1 y 0,5: más lento, para poder frenar en el valor justo
FACTOR := 1.03       ; cada paso libre agranda/achica un 3 % (fino en tamaños chicos, rápido en grandes)
MAXIMO_STROKE := 400 ; tope del Stroke, en pt
ARCHIVO_INI := A_ScriptDir "\pincel.ini"
; Teclas que se pueden elegir: nombre en pantalla y nombre para AutoHotkey. Shift y Alt quedan afuera: son el gesto.
TECLAS := Map("Ctrl", "Control", "Bloq Mayús", "CapsLock", "Tab", "Tab", "Espacio", "Space")
loop 26
    TECLAS[Chr(64 + A_Index)] := Chr(96 + A_Index)
loop 12
    TECLAS["F" A_Index] := "F" A_Index
FABRICA := Map("Libre", 50, "UnPaso", 50, "MedioPaso", 50, "TeclaUnPaso", "Control", "TeclaMedioPaso", "CapsLock", "TeclaUnidad", "a")
SI_AJUSTANDO := (*) => ajustando
; Preferencia strokeUnits de Illustrator: puntos por unidad y nombre
UNIDADES := Map(0, [72, "in"], 1, [72 / 25.4, "mm"], 2, [1, "pt"], 3, [12, "pc"], 4, [72 / 2.54, "cm"], 5, [72 / 101.6, "Q"], 6, [1, "px"])
; Diagnóstico: solo registra si ya existe este archivo, que el instalador no crea
REGISTRO := A_Temp "\pincel-atajo.log"
ajustando := false
movido := 0
ultimoAbsoluto := ""
; El simulador de la ventana de ajustes usa el mismo gesto, sin Illustrator
ventanaAjustes := 0
areaSimulador := 0
simAncho := 40
simUnidad := 2
configurando := A_Args.Length && A_Args[1] = "/configurar" ; lo abre el instalador: al cerrar la ventana, termina

A_IconTip := "Atajo de pincel: Shift + Alt en Illustrator"
A_TrayMenu.Delete()
A_TrayMenu.Add("Ajustes…", AbrirAjustes)
A_TrayMenu.Add("Salir", Salir)
A_TrayMenu.Default := "Ajustes…"
ajustes := LeerAjustes()
AplicarAjustes()
; El arranque con Windows y el final del instalador pasan /arranque: abrirlo a mano muestra los ajustes, así se ve que anda.
if !(A_Args.Length && A_Args[1] = "/arranque")
    AbrirAjustes()

; Mientras se ajusta, Illustrator y Windows no ven estas teclas: así no cambian de herramienta ni el idioma del teclado
#HotIf ajustando
*LShift::
*RShift::
*LAlt::
*RAlt:: return
; Solo en la ventana principal: con un diálogo abierto, Illustrator no responde hasta cerrarlo.
; Alt+arrastrar mientras dibujás es de Illustrator (cerrar el trazo)
#HotIf (WinActive("ahk_class illustrator ahk_exe Illustrator.exe") || EnSimulador()) && !GetKeyState("LButton", "P")
+LAlt::
+RAlt::
!LShift::
!RShift:: Ajustar()
#HotIf

Ajustar() {
    global ajustando, movido, ultimoAbsoluto, simAncho, simUnidad
    if ajustando
        return
    Anotar("inicio " A_ThisHotkey " " TeclasLogicas())
    simulando := EnSimulador()
    datos := []
    if simulando
        datos := [simAncho, simUnidad]
    else if IllustratorResponde() {
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
    ajustando := true
    ; Si Alt llegó antes que Shift, se lo retira a Illustrator para que vuelva la vista previa
    SoltarTeclas(["LAlt", "RAlt"])
    CoordMode "Mouse", "Screen"
    CoordMode "ToolTip", "Screen"
    MouseGetPos &x0, &y0
    Etiqueta(ancho, 0, unidad, x0, y0)
    movido := 0, ultimoAbsoluto := "", modo := 0, seSolto := true
    unidadApretada := GetKeyState(ajustes["TeclaUnidad"], "P")
    EscucharMouse(true)
    BlockInput "MouseMove" ; el cursor queda quieto (antes temblaba al devolverlo a su lugar) y el movimiento se lee crudo
    while GetKeyState("Shift", "P") && GetKeyState("Alt", "P") {
        if GetKeyState("LButton", "P") { ; Shift + Alt + arrastrar es de Illustrator: se le devuelve Alt
            seSolto := false
            break
        }
        ; Solo al apretarla: mantenida se repite y alternaría sin parar
        estaApretada := GetKeyState(ajustes["TeclaUnidad"], "P")
        cambio := estaApretada && !unidadApretada
        unidadApretada := estaApretada
        if cambio {
            nueva := unidad[2] = "mm" ? 2 : 1
            if simulando {
                simUnidad := nueva
                unidad := UNIDADES[nueva]
                movido := 0
                Etiqueta(ancho, modo, unidad, x0, y0)
            } else if IllustratorResponde()
                try {
                    ai.DoJavaScript("app.preferences.setIntegerPreference('strokeUnits', " nueva ")")
                    unidad := UNIDADES[nueva]
                    movido := 0
                    Etiqueta(ancho, modo, unidad, x0, y0)
                }
        }
        nuevoModo := GetKeyState(ajustes["TeclaMedioPaso"], "P") ? 0.5 : GetKeyState(ajustes["TeclaUnPaso"], "P") ? 1 : 0
        if (nuevoModo != modo) {
            modo := nuevoModo, movido := 0
            Etiqueta(ancho, modo, unidad, x0, y0)
        }
        porPaso := MovimientoPorPaso(modo)
        pasos := movido > 0 ? Floor(movido / porPaso) : -Floor(-movido / porPaso)
        if pasos {
            movido -= pasos * porPaso
            ancho := SiguienteAncho(ancho, pasos, modo, unidad[1])
            Etiqueta(ancho, modo, unidad, x0, y0)
            if simulando {
                simAncho := ancho
                DibujarSimulador()
            } else if IllustratorResponde()
                try ai.DoJavaScript("app.activeDocument.defaultStrokeWidth = " ancho)
        }
        Sleep 5
    }
    BlockInput "MouseMoveOff"
    EscucharMouse(false)
    ToolTip
    if seSolto {
        ; Hasta soltar todo siguen bloqueadas: si no, la tecla que queda apretada le llegaría a Illustrator al repetirse
        while AlgunaTeclaApretada()
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
SoltarTeclas(teclas := ["LShift", "RShift", "LAlt", "RAlt", "LControl", "RControl"]) {
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
    if AlgunaTeclaApretada()
        return
    SetTimer SoltarAlTerminar, 0
    SoltarTeclas()
    Anotar("destrabado " TeclasLogicas())
}

AlgunaTeclaApretada() {
    for tecla in ["Shift", "Alt", ajustes["TeclaUnPaso"], ajustes["TeclaMedioPaso"], ajustes["TeclaUnidad"]]
        if GetKeyState(tecla, "P")
            return true
    return false
}

IllustratorResponde() {
    respondio := DllCall("SendMessageTimeout", "ptr", WinExist("ahk_class illustrator ahk_exe Illustrator.exe"), "uint", 0, "ptr", 0, "ptr", 0, "uint", 0x2, "uint", 200, "ptr*", &r := 0, "ptr") ; WM_NULL, SMTO_ABORTIFHUNG
    return respondio != 0
}

TeclasLogicas() {
    s := ""
    for tecla in ["LShift", "RShift", "LAlt", "RAlt", "LControl", "RControl"]
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

; Sensibilidad de 0 a 100: 50 es el valor de fábrica, 100 va cuatro veces más rápido y 0 cuatro veces más lento
MovimientoPorPaso(modo) {
    if modo
        return BASE_FIJO * 4 ** ((50 - ajustes[modo = 1 ? "UnPaso" : "MedioPaso"]) / 50)
    return BASE_LIBRE * 4 ** ((50 - ajustes["Libre"]) / 50)
}

; Un archivo tocado a mano o roto no puede dejar el atajo sin funcionar: lo que no sirve vuelve al valor de fábrica
LeerAjustes() {
    leidos := Map()
    for clave in ["Libre", "UnPaso", "MedioPaso"] {
        v := IniRead(ARCHIVO_INI, "Sensibilidad", clave, "")
        leidos[clave] := IsInteger(v) && v >= 0 && v <= 100 ? v + 0 : FABRICA[clave]
    }
    teclasValidas := Map()
    for , tecla in TECLAS
        teclasValidas[tecla] := true
    for clave in ["TeclaUnPaso", "TeclaMedioPaso", "TeclaUnidad"] {
        v := IniRead(ARCHIVO_INI, "Teclas", clave, "")
        leidos[clave] := teclasValidas.Has(v) ? v : FABRICA[clave]
    }
    if leidos["TeclaUnPaso"] = leidos["TeclaMedioPaso"] || leidos["TeclaUnPaso"] = leidos["TeclaUnidad"] || leidos["TeclaMedioPaso"] = leidos["TeclaUnidad"]
        for clave in ["TeclaUnPaso", "TeclaMedioPaso", "TeclaUnidad"]
            leidos[clave] := FABRICA[clave]
    return leidos
}

; Mientras se ajusta, Illustrator no ve las teclas elegidas: así no cambian de herramienta
AplicarAjustes() {
    static activas := []
    HotIf SI_AJUSTANDO
    for h in activas
        Hotkey "*" h, "Off"
    activas := []
    for clave in ["TeclaUnPaso", "TeclaMedioPaso", "TeclaUnidad"]
        for h in ajustes[clave] = "Control" ? ["LControl", "RControl"] : [ajustes[clave]] {
            Hotkey "*" h, (*) => 0, "On"
            activas.Push(h)
        }
    HotIf
}

NombreDeTecla(tecla) {
    for nombre, valor in TECLAS
        if valor = tecla
            return nombre
}

EnSimulador() => ventanaAjustes && WinActive("ahk_id " ventanaAjustes)

; Un círculo que crece hasta llenar el recuadro al llegar al tope. No es a tamaño real: sirve para sentir la velocidad.
DibujarSimulador() {
    if !areaSimulador
        return
    areaSimulador.GetPos(, , &w, &h)
    hdc := DllCall("GetDC", "ptr", areaSimulador.Hwnd, "ptr")
    r := Buffer(16), NumPut("int", 0, "int", 0, "int", w, "int", h, r)
    DllCall("FillRect", "ptr", hdc, "ptr", r, "ptr", DllCall("GetStockObject", "int", 0, "ptr"))
    d := Max(3, Round(simAncho / MAXIMO_STROKE * (h - 12)))
    pincel := DllCall("CreateSolidBrush", "uint", 0x2A2AFF, "ptr")
    anterior := DllCall("SelectObject", "ptr", hdc, "ptr", pincel, "ptr")
    x := (w - d) // 2, y := (h - d) // 2
    DllCall("Ellipse", "ptr", hdc, "int", x, "int", y, "int", x + d, "int", y + d)
    DllCall("SelectObject", "ptr", hdc, "ptr", anterior, "ptr")
    DllCall("DeleteObject", "ptr", pincel)
    DllCall("ReleaseDC", "ptr", areaSimulador.Hwnd, "ptr", hdc)
}

; Lo que se toca rige enseguida, así el simulador lo refleja. Cancelar vuelve a como estaba.
AbrirAjustes(*) {
    global ventanaAjustes, areaSimulador
    static ventana := 0
    if ventana {
        ventana.Show()
        return
    }
    respaldo := ajustes.Clone()
    nombres := []
    for nombre in ["Ctrl", "Bloq Mayús", "Tab", "Espacio"]
        nombres.Push(nombre)
    loop 26
        nombres.Push(Chr(64 + A_Index))
    loop 12
        nombres.Push("F" A_Index)

    ventana := Gui(, "Atajo de pincel para Illustrator")
    ventana.SetFont("s10", "Segoe UI")
    ventana.SetFont("bold")
    ventana.AddText("w400", "Probá la velocidad")
    ventana.SetFont("norm")
    ventana.AddText("w400 cGray", "Con esta ventana al frente, apretá Shift, después Alt, y mové el mouse sin hacer clic. Sumá las teclas de abajo para probar cada modo. No hace falta tener Illustrator abierto.")
    areaSimulador := ventana.AddText("w400 h130 Border")
    ventana.SetFont("bold")
    ventana.AddText("xm w400 y+16", "Sensibilidad")
    ventana.SetFont("norm")
    ventana.AddText("w400 cGray", "A la izquierda, más lento. A la derecha, más rápido.")
    deslizadores := Map()
    for clave, texto in Map("Libre", "Libre", "MedioPaso", "De a 0,5", "UnPaso", "De a 1") {
        ventana.AddText("xm w90 y+12", texto)
        deslizadores[clave] := ventana.AddSlider("x+8 yp-4 w300 Range0-100 TickInterval50 AltSubmit", ajustes[clave])
        deslizadores[clave].OnEvent("Change", SensibilidadCambiada.Bind(clave))
    }
    ventana.SetFont("bold")
    ventana.AddText("xm w400 y+20", "Teclas que se suman a Shift + Alt")
    ventana.SetFont("norm")
    listas := Map()
    for clave, texto in Map("TeclaMedioPaso", "De a 0,5", "TeclaUnPaso", "De a 1", "TeclaUnidad", "Pasar entre pt y mm") {
        ventana.AddText("xm w170 y+12", texto)
        listas[clave] := ventana.AddDropDownList("x+8 yp-4 w120 r12", nombres)
        listas[clave].Text := NombreDeTecla(ajustes[clave])
        listas[clave].OnEvent("Change", TeclaCambiada.Bind(clave))
    }
    ventana.AddText("xm w400 y+16 cGray", "Shift + Alt queda fijo: otras teclas cambian de herramienta en Illustrator y esconden el círculo.")

    SensibilidadCambiada(clave, control, *) {
        ajustes[clave] := control.Value
    }
    TeclaCambiada(clave, control, *) {
        ajustes[clave] := TECLAS[control.Text]
        AplicarAjustes()
    }
    Cerrar() {
        global ventanaAjustes, areaSimulador
        ventana.Destroy()
        ventana := 0
        ventanaAjustes := 0
        areaSimulador := 0
        if configurando
            ExitApp
    }
    Cancelar(*) {
        global ajustes
        ajustes := respaldo
        AplicarAjustes()
        Cerrar()
    }
    Guardar(*) {
        elegidas := Map()
        for clave, lista in listas {
            if elegidas.Has(lista.Text) {
                MsgBox "Cada acción necesita una tecla distinta.", "Atajo de pincel para Illustrator", "Icon! Owner" ventana.Hwnd
                return
            }
            elegidas[lista.Text] := true
        }
        for clave, deslizador in deslizadores
            ajustes[clave] := deslizador.Value
        for clave, lista in listas
            ajustes[clave] := TECLAS[lista.Text]
        AplicarAjustes()
        try {
            for clave in deslizadores
                IniWrite ajustes[clave], ARCHIVO_INI, "Sensibilidad", clave
            for clave in listas
                IniWrite ajustes[clave], ARCHIVO_INI, "Teclas", clave
        } catch {
            MsgBox "No se pudo guardar en " ARCHIVO_INI, "Atajo de pincel para Illustrator", "Icon! Owner" ventana.Hwnd
            return
        }
        Cerrar()
    }
    Restablecer(*) {
        for clave, deslizador in deslizadores {
            ajustes[clave] := FABRICA[clave]
            deslizador.Value := FABRICA[clave]
        }
        for clave, lista in listas {
            ajustes[clave] := FABRICA[clave]
            lista.Text := NombreDeTecla(FABRICA[clave])
        }
        AplicarAjustes()
    }
    ventana.AddButton("xm y+16 w100 Default", "Guardar").OnEvent("Click", Guardar)
    ventana.AddButton("x+8 w100", "Cancelar").OnEvent("Click", Cancelar)
    ventana.AddButton("x+8 w184", "Valores de fábrica").OnEvent("Click", Restablecer)
    ventana.OnEvent("Close", Cancelar)
    ventana.OnEvent("Escape", Cancelar)
    ventana.Show()
    ventanaAjustes := ventana.Hwnd
    SetTimer DibujarSimulador, -200
}

Salir(*) {
    if MsgBox("¿Cerrar el atajo?`n`nShift + Alt va a dejar de funcionar hasta que lo vuelvas a abrir desde el menú Inicio (busca «Atajo de pincel para Illustrator»). Si dejaste activado el arranque con Windows, también vuelve solo al reiniciar.`n`nIllustrator y tus archivos no se ven afectados.", "Atajo de pincel para Illustrator", "YesNo Icon?") = "Yes"
        ExitApp
}
