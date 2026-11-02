#Requires AutoHotkey v2.0
#SingleInstance Force
; Illustrator: Shift + Alt + mover el mouse (sin hacer clic) = tamaño del pincel, como Alt + clic derecho en Photoshop.
; Derecha agranda, izquierda achica. Mientras ajustás se ve el círculo rojo del pincel a escala real y el tamaño abajo.
; Cambia el grosor de trazo de lo próximo que dibujes (Pincel, Lápiz, Pluma…), igual que el campo «Stroke» de arriba.

DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr") ; píxeles reales en los dos monitores
A_MenuMaskKey := "vkE8"
PASO := 4         ; píxeles de movimiento por cada paso
FACTOR := 1.06    ; cada paso agranda/achica un 6 % (fino en tamaños chicos, rápido en grandes)
ARCHIVO_INI := A_ScriptDir "\pincel.ini"
PINCEL_PT := LeerNumero("PincelPt", 5, 0.1, 1000)   ; tamaño del pincel: el trazo lo multiplica. Se mide del último trazo dibujado (ver LEER_ESTADO)
MAXIMO_PT := LeerNumero("MaximoPt", 400, 0.1, 5000) ; grosor máximo de la línea

; Illustrator no dice qué pincel está elegido, pero un trazo ya dibujado sí lo delata: lo que el pincel le suma a
; su contorno, dividido por su Stroke, es el tamaño del pincel. Si no hay trazo, el tercer dato queda vacío.
LEER_ESTADO := "
(
(function () {
    if (!app.documents.length) return '';
    var d = app.activeDocument, medido = '';
    try {
        var c = d.activeLayer.pathItems;
        if (c.length && c[0].stroked && !c[0].closed && c[0].strokeWidth > 0) {
            var g = c[0].geometricBounds, v = c[0].visibleBounds;
            medido = Math.max((v[2] - v[0]) - (g[2] - g[0]), (v[1] - v[3]) - (g[1] - g[3])) / c[0].strokeWidth;
        }
    } catch (e) {}
    return d.defaultStrokeWidth + '|' + d.activeView.zoom + '|' + medido;
})()
)"

;@Ahk2Exe-SetDescription Atajo de pincel para Illustrator
;@Ahk2Exe-SetName Atajo de pincel para Illustrator
A_IconTip := "Atajo de pincel: Shift + Alt en Illustrator"
A_TrayMenu.Delete()
A_TrayMenu.Add("Cambiar tamaño del pincel…", CambiarTamano)
A_TrayMenu.Add("Salir", (*) => ExitApp())
A_TrayMenu.Default := "Cambiar tamaño del pincel…"

#HotIf WinActive("ahk_exe Illustrator.exe")
~+Alt::
~!Shift:: Ajustar()
#HotIf

; Mientras se ajusta, Illustrator no recibe las repeticiones de Shift/Alt: con cada una volvía a mostrar su cursor
#HotIf Aro.hwnd
*LShift::
*RShift::
*LAlt::
*RAlt:: return
#HotIf

LeerNumero(clave, porDefecto, minimo, maximo) {
    v := NumeroValido(IniRead(ARCHIVO_INI, "Pincel", clave, ""), minimo, maximo)
    return v = "" ? porDefecto : v
}

; Acepta coma o punto decimal. Devuelve "" si no es un número dentro del rango.
NumeroValido(texto, minimo, maximo) {
    v := StrReplace(Trim(texto), ",", ".")
    return IsNumber(v) && v + 0 >= minimo && v + 0 <= maximo ? v + 0 : ""
}

; La medición varía unas centésimas según la forma del trazo: solo cuenta si cambió de verdad
ActualizarPincel(medido) {
    global PINCEL_PT
    v := NumeroValido(medido, 0.1, 1000)
    if v = "" || Abs(v - PINCEL_PT) <= PINCEL_PT * 0.05
        return
    PINCEL_PT := Round(v, 2)
    try IniWrite PINCEL_PT, ARCHIVO_INI, "Pincel", "PincelPt"
}

CambiarTamano(*) {
    global PINCEL_PT, MAXIMO_PT
    pincel := PedirNumero("Tamaño de tu pincel en pt.`nEl atajo lo vuelve a medir solo cuando dibujás un trazo.", PINCEL_PT, 0.1, 1000)
    if pincel = ""
        return
    maximo := PedirNumero("Grosor máximo de la línea en pt.", MAXIMO_PT, pincel, 5000)
    if maximo = ""
        return
    try {
        IniWrite pincel, ARCHIVO_INI, "Pincel", "PincelPt"
        IniWrite maximo, ARCHIVO_INI, "Pincel", "MaximoPt"
    } catch {
        MsgBox "No se pudo guardar en " ARCHIVO_INI, "Atajo de pincel", "Icon!"
        return
    }
    PINCEL_PT := pincel, MAXIMO_PT := maximo
}

PedirNumero(texto, actual, minimo, maximo) {
    loop {
        r := InputBox(texto, "Atajo de pincel", "w360 h150", actual)
        if r.Result != "OK"
            return ""
        v := NumeroValido(r.Value, minimo, maximo)
        if v != ""
            return v
        MsgBox "Escribí un número entre " minimo " y " maximo ".", "Atajo de pincel", "Icon!"
    }
}

Ajustar() {
    static activo := false
    if activo || GetKeyState("LButton", "P") ; Alt+arrastrar mientras dibujás es de Illustrator (cerrar el trazo)
        return
    try {
        ai := ComObjActive("Illustrator.Application")
        datos := StrSplit(ai.DoJavaScript(LEER_ESTADO), "|")
    } catch
        return
    if datos.Length < 3
        return
    ancho := datos[1] + 0, zoom := datos[2] + 0
    ActualizarPincel(datos[3])
    activo := true
    CoordMode "Mouse", "Screen"
    MouseGetPos &x0, &y0
    escala := zoom * DpiMonitor(x0, y0) / 96 ; puntos del documento → píxeles de pantalla
    circulo := Aro()
    circulo.Dibujar(x0, y0, ancho, escala)
    acum := 0
    while GetKeyState("Shift", "P") && GetKeyState("Alt", "P") {
        MouseGetPos &x
        if (x != x0) {
            acum += x - x0
            DllCall("SetCursorPos", "int", x0, "int", y0)
        }
        pasos := acum > 0 ? Floor(acum / PASO) : -Floor(-acum / PASO)
        if pasos {
            acum -= pasos * PASO
            ancho := Max(0.01, Min(MAXIMO_PT / PINCEL_PT, Round(ancho * FACTOR ** pasos, 3)))
            circulo.Dibujar(x0, y0, ancho, escala)
            try ai.DoJavaScript("app.activeDocument.defaultStrokeWidth = " ancho)
        }
        DllCall("SetCursor", "ptr", 0)
        Sleep 5
    }
    circulo.Cerrar()
    ; Que soltar Alt+Shift no cambie el idioma del teclado ni abra el menú de Illustrator, y que Illustrator
    ; se entere de que se soltaron (las teclas quedaron bloqueadas mientras se ajustaba)
    Send "{Blind}{vkE8}"
    Send "{Blind}{LShift up}{RShift up}{LAlt up}{RAlt up}"
    activo := false
}

DpiMonitor(x, y) {
    mon := DllCall("MonitorFromPoint", "int64", (x & 0xFFFFFFFF) | (y << 32), "uint", 2, "ptr")
    dpi := 96
    try DllCall("Shcore\GetDpiForMonitor", "ptr", mon, "int", 0, "uint*", &dpi, "uint*", &dpiY := 0)
    return dpi
}

/**
 * Ventana transparente y siempre arriba con el círculo del pincel (degradé rojo) y el tamaño abajo.
 * Queda bajo el cursor y lo oculta: así no se ve el cursor de Illustrator temblando en el centro.
 */
class Aro {
    static token := 0, hwnd := 0

    __New() {
        if !Aro.token {
            DllCall("LoadLibrary", "str", "gdiplus", "ptr")
            si := Buffer(24, 0), NumPut("uint", 1, si)
            DllCall("gdiplus\GdiplusStartup", "ptr*", &t := 0, "ptr", si, "ptr", 0)
            Aro.token := t
            OnMessage(0x20, (w, l, m, h) => Aro.OcultarCursor(w, l, m, h)) ; WM_SETCURSOR
        }
        this.gui := Gui("-Caption +E0x80000 +E0x08000000 +AlwaysOnTop +ToolWindow -DPIScale") ; capas, sin activarse
        this.gui.Show("NA x-10 y-10 w1 h1")
        Aro.hwnd := this.gui.Hwnd
    }

    static OcultarCursor(wParam, lParam, msg, hwnd) {
        if (hwnd = Aro.hwnd) {
            DllCall("SetCursor", "ptr", 0)
            return 1
        }
    }

    Dibujar(cx, cy, anchoPt, escala) {
        d := Max(4, Min(4000, PINCEL_PT * anchoPt * escala)) ; diámetro en pantalla
        etiqueta := Format("Ø {:.2f} pt  ·  {:.2f} mm", PINCEL_PT * anchoPt, PINCEL_PT * anchoPt * 25.4 / 72)
        ; Ventana cuadrada centrada en el cursor, de al menos 400 px: aunque muevas rápido, el cursor no sale de ella
        m := 3, altoEt := 26, anchoEt := 200
        W := H := Ceil(Max(d + 2 * (m + 8 + altoEt), 400))
        ex := ey := (W - d) / 2

        bi := Buffer(40, 0)
        NumPut("uint", 40, "int", W, "int", -H, "ushort", 1, "ushort", 32, bi)
        hdc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
        hbm := DllCall("CreateDIBSection", "ptr", hdc, "ptr", bi, "uint", 0, "ptr*", &bits := 0, "ptr", 0, "uint", 0, "ptr")
        obm := DllCall("SelectObject", "ptr", hdc, "ptr", hbm, "ptr")
        DllCall("gdiplus\GdipCreateFromHDC", "ptr", hdc, "ptr*", &g := 0)
        DllCall("gdiplus\GdipSetSmoothingMode", "ptr", g, "int", 4)
        DllCall("gdiplus\GdipSetTextRenderingHint", "ptr", g, "int", 4)
        DllCall("gdiplus\GdipGraphicsClear", "ptr", g, "uint", 0x01000000) ; fondo invisible pero «tocable» (atrapa el cursor)

        ; Relleno: degradé radial rojo, más intenso al centro
        DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &path := 0)
        DllCall("gdiplus\GdipAddPathEllipse", "ptr", path, "float", ex, "float", ey, "float", d, "float", d)
        DllCall("gdiplus\GdipCreatePathGradientFromPath", "ptr", path, "ptr*", &pb := 0)
        DllCall("gdiplus\GdipSetPathGradientCenterColor", "ptr", pb, "uint", 0x99FF2A2A)
        borde := Buffer(4), NumPut("uint", 0x2EFF2A2A, borde)
        DllCall("gdiplus\GdipSetPathGradientSurroundColorsWithCount", "ptr", pb, "ptr", borde, "int*", &n := 1)
        DllCall("gdiplus\GdipFillPath", "ptr", g, "ptr", pb, "ptr", path)
        ; Contorno doble (blanco y oscuro) para que se vea sobre cualquier fondo
        DllCall("gdiplus\GdipCreatePen1", "uint", 0xF0FFFFFF, "float", 1.5, "int", 2, "ptr*", &p1 := 0)
        DllCall("gdiplus\GdipCreatePen1", "uint", 0xB0000000, "float", 1, "int", 2, "ptr*", &p2 := 0)
        DllCall("gdiplus\GdipDrawEllipse", "ptr", g, "ptr", p2, "float", ex - 1, "float", ey - 1, "float", d + 2, "float", d + 2)
        DllCall("gdiplus\GdipDrawEllipse", "ptr", g, "ptr", p1, "float", ex, "float", ey, "float", d, "float", d)

        ; Etiqueta abajo del círculo
        ty := ey + d + 8, tx := (W - anchoEt) / 2
        DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xE0202020, "ptr*", &fondo := 0)
        DllCall("gdiplus\GdipFillRectangle", "ptr", g, "ptr", fondo, "float", tx, "float", ty, "float", anchoEt, "float", altoEt)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", "Segoe UI", "ptr", 0, "ptr*", &fam := 0)
        DllCall("gdiplus\GdipCreateFont", "ptr", fam, "float", 13, "int", 1, "int", 2, "ptr*", &fuente := 0)
        DllCall("gdiplus\GdipCreateStringFormat", "int", 0, "int", 0, "ptr*", &fmt := 0)
        DllCall("gdiplus\GdipSetStringFormatAlign", "ptr", fmt, "int", 1)
        DllCall("gdiplus\GdipSetStringFormatLineAlign", "ptr", fmt, "int", 1)
        DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xFFFFFFFF, "ptr*", &blanco := 0)
        rect := Buffer(16), NumPut("float", tx, "float", ty, "float", anchoEt, "float", altoEt, rect)
        DllCall("gdiplus\GdipDrawString", "ptr", g, "wstr", etiqueta, "int", -1, "ptr", fuente, "ptr", rect, "ptr", fmt, "ptr", blanco)

        ; A la pantalla: el centro del círculo queda sobre el cursor
        pos := Buffer(8), NumPut("int", Round(cx - W / 2), "int", Round(cy - ey - d / 2), pos)
        tam := Buffer(8), NumPut("int", W, "int", H, tam)
        org := Buffer(8, 0)
        DllCall("UpdateLayeredWindow", "ptr", this.gui.Hwnd, "ptr", 0, "ptr", pos, "ptr", tam, "ptr", hdc, "ptr", org, "uint", 0, "uint*", 0x01FF0000, "uint", 2)

        DllCall("gdiplus\GdipDeleteBrush", "ptr", pb)
        DllCall("gdiplus\GdipDeletePath", "ptr", path)
        DllCall("gdiplus\GdipDeletePen", "ptr", p1)
        DllCall("gdiplus\GdipDeletePen", "ptr", p2)
        DllCall("gdiplus\GdipDeleteBrush", "ptr", fondo)
        DllCall("gdiplus\GdipDeleteBrush", "ptr", blanco)
        DllCall("gdiplus\GdipDeleteFont", "ptr", fuente)
        DllCall("gdiplus\GdipDeleteFontFamily", "ptr", fam)
        DllCall("gdiplus\GdipDeleteStringFormat", "ptr", fmt)
        DllCall("gdiplus\GdipDeleteGraphics", "ptr", g)
        DllCall("SelectObject", "ptr", hdc, "ptr", obm)
        DllCall("DeleteObject", "ptr", hbm)
        DllCall("DeleteDC", "ptr", hdc)
    }

    Cerrar() {
        Aro.hwnd := 0
        this.gui.Destroy()
    }
}
