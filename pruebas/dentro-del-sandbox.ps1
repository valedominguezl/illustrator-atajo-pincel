# Corre dentro de Windows Sandbox (lo lanza probar-en-sandbox.ps1). Prueba el instalador de punta a punta y deja
# en la carpeta de resultados un informe y capturas de cada página del asistente. El gesto en Illustrator no se prueba acá.
param([string]$Instalador, [string]$Resultados)

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
# El asistente de Inno Setup no expone botones por UI Automation: se maneja con mensajes de Windows
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class W {
    delegate bool Cb(IntPtr h, IntPtr l);
    [DllImport("user32")] static extern bool EnumWindows(Cb c, IntPtr l);
    [DllImport("user32")] static extern bool EnumChildWindows(IntPtr p, Cb c, IntPtr l);
    [DllImport("user32", CharSet = CharSet.Unicode)] static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32", CharSet = CharSet.Unicode)] static extern IntPtr SendMessageTimeoutW(IntPtr h, uint m, IntPtr w, StringBuilder s, uint f, uint ms, out IntPtr r);
    [DllImport("user32")] static extern int GetWindowThreadProcessId(IntPtr h, out int pid);
    [DllImport("user32", CharSet = CharSet.Unicode, EntryPoint = "SendMessageW")] static extern IntPtr SendTexto(IntPtr h, uint m, IntPtr w, string s);
    [DllImport("user32")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowW(string c, string t);
    public static string Clase(IntPtr h) { var s = new StringBuilder(256); GetClassNameW(h, s, 256); return s.ToString(); }
    public static string Texto(IntPtr h) {
        var s = new StringBuilder(4096); IntPtr r;
        if (SendMessageTimeoutW(h, 0x0D, (IntPtr)4096, s, 2, 2000, out r) != IntPtr.Zero) return s.ToString();
        int pid; GetWindowThreadProcessId(h, out pid);
        var linea = "      no responde: [" + Clase(h) + "] proceso " + pid + " " + System.Diagnostics.Process.GetProcessById(pid).ProcessName;
        if (!NoResponden.Contains(linea)) NoResponden.Add(linea);
        return "";
    }
    public static List<string> NoResponden = new List<string>();
    [DllImport("user32", EntryPoint = "SendMessageTimeoutW")] static extern IntPtr SendNum(IntPtr h, uint m, IntPtr w, IntPtr l, uint f, uint ms, out IntPtr r);
    public static int Enviar(IntPtr h, uint m, int w, int l) { IntPtr r; SendNum(h, m, (IntPtr)w, (IntPtr)l, 2, 2000, out r); return (int)r; }
    public static void PonerTexto(IntPtr h, string t) { SendTexto(h, 0x0C, IntPtr.Zero, t); }
    static IntPtr[] Visibles(Action<Cb> enumerar) {
        var r = new List<IntPtr>();
        enumerar((h, l) => { if (IsWindowVisible(h)) r.Add(h); return true; });
        return r.ToArray();
    }
    public static IntPtr[] Superiores() { return Visibles(c => EnumWindows(c, IntPtr.Zero)); }
    public static IntPtr[] Hijos(IntPtr p) { return Visibles(c => EnumChildWindows(p, c, IntPtr.Zero)); }
}
'@

$nombre = 'Atajo de pincel para Illustrator'
$app = "$env:LOCALAPPDATA\Programs\$nombre"
$exe = "$app\PincelIllustrator.exe"
$lnkInicio = "$([Environment]::GetFolderPath('Startup'))\$nombre.lnk"
$lnkMenu = "$([Environment]::GetFolderPath('Programs'))\$nombre.lnk"
$ini = "$app\pincel.ini"
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{5E34864E-8941-4C6D-951E-7877ECFA8A73}_is1'
$informe = "$Resultados\informe.txt"
$script:fallos = 0

# Un error inesperado tiene que llegar al informe: si no, afuera solo se ve que nunca termina
trap {
    Anotar "`nERROR en la línea $($_.InvocationInfo.ScriptLineNumber): $_"
    Anotar 'Ventanas abiertas:'
    foreach ($v in [W]::Superiores()) {
        Anotar "      [$([W]::Clase($v))] $([W]::Texto($v))"
        foreach ($h in [W]::Hijos($v)) { Anotar "          [$([W]::Clase($h))] $([W]::Texto($h))" }
    }
    Captura 'error'
    Anotar 'FALLAS: prueba interrumpida'
    'terminado' | Set-Content "$Resultados\terminado.txt"
    exit 1
}

function Anotar($texto) { $texto | Tee-Object -FilePath $informe -Append | Out-Host }
function Comprobar($descripcion, $condicion) {
    if ($condicion) { Anotar "OK    $descripcion" } else { Anotar "FALLA $descripcion"; $script:fallos++ }
}
function Corriendo { [bool](Get-Process PincelIllustrator -ErrorAction SilentlyContinue) }
function Instalar([string[]]$argumentos) {
    # Sin -Wait: también esperaría al atajo que el instalador deja corriendo, que nunca termina
    $p = Start-Process $Instalador -ArgumentList (@('/VERYSILENT', '/SUPPRESSMSGBOXES') + $argumentos) -PassThru
    $null = $p.Handle # sin esto, ExitCode queda vacío
    if (-not $p.WaitForExit(90000)) { throw 'El instalador no terminó en 90 segundos' }
    Start-Sleep 2
    return $p.ExitCode
}
function Desinstalar {
    $u = (Get-ItemProperty $uninstallKey).UninstallString.Trim('"')
    $p = Start-Process $u -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES' -Wait -PassThru
    Start-Sleep 3 # el desinstalador termina de borrarse a sí mismo después de salir
    return $p.ExitCode
}
function Foto {
    # Todo lo que el instalador podría tocar en la cuenta, para comparar antes y después
    $rutas = "$env:LOCALAPPDATA\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop"
    $archivos = Get-ChildItem $rutas -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
    $claves = Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | ForEach-Object Name
    # TileProperties es una caché que el menú Inicio de Windows crea solo y cuando quiere: no la pone el instalador
    $general = reg query HKCU /f 'pincel' /s /k 2>$null | Where-Object { $_ -match '^HKEY' -and $_ -notmatch '\\Start\\TileProperties\\' }
    return @($archivos) + @($claves) + @($general) | Sort-Object
}
function Captura($nombreArchivo) {
    $r = [Windows.Forms.Screen]::PrimaryScreen.Bounds
    $b = New-Object Drawing.Bitmap $r.Width, $r.Height
    $g = [Drawing.Graphics]::FromImage($b)
    $g.CopyFromScreen($r.Location, [Drawing.Point]::Empty, $r.Size)
    $b.Save("$Resultados\$nombreArchivo.png", [Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $b.Dispose()
}
# Ventana visible por clase o por título, esperando a que aparezca
function Ventana($clase, $titulo = '*', $segundos = 20) {
    for ($i = 0; $i -lt $segundos * 4; $i++) {
        foreach ($v in [W]::Superiores()) {
            if ([W]::Clase($v) -like $clase -and [W]::Texto($v) -like $titulo) { return $v }
        }
        Start-Sleep -Milliseconds 250
    }
    return $null
}
function Tocar($ventana, $texto) {
    for ($i = 0; $i -lt 120; $i++) {
        foreach ($h in [W]::Hijos($ventana)) {
            if ([W]::Clase($h) -match 'Button' -and ([W]::Texto($h) -replace '&', '') -like $texto) {
                [W]::PostMessageW($h, 0xF5, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null # BM_CLICK
                Start-Sleep -Milliseconds 900
                return
            }
        }
        Start-Sleep -Milliseconds 250
    }
    throw "No está el botón '$texto'"
}
function Campos($ventana) { @([W]::Hijos($ventana) | Where-Object { [W]::Clase($_) -match 'Edit' }) }

Anotar "Prueba: $(Get-Date -Format s)  $Instalador  SHA-256 $((Get-FileHash $Instalador).Hash)"

Anotar "`n== PC limpia"
Comprobar 'sin AutoHotkey instalado' (-not (Get-Command AutoHotkey64 -ErrorAction SilentlyContinue) -and -not (Test-Path "$env:ProgramFiles\AutoHotkey") -and -not (Test-Path "$env:LOCALAPPDATA\Programs\AutoHotkey"))
$fotoAntes = Foto

Anotar "`n== Asistente"
$proceso = Start-Process $Instalador -PassThru
$w = Ventana 'TWizardForm'
if (-not $w) { throw 'No apareció la ventana del asistente' }
Start-Sleep 1
Captura '1-bienvenida'
Tocar $w 'Siguiente*'
Comprobar 'el asistente no pide escribir nada' ((Campos $w).Count -eq 0)
Captura '4-tareas' # sin tocar nada: la opción de arrancar con Windows tiene que venir tildada
Tocar $w 'Siguiente*'
Captura '5-listo'
Tocar $w 'Instalar*'
Start-Sleep 5
Captura '6-fin'
Tocar $w 'Finalizar*' # si todavía está instalando, espera
$proceso.WaitForExit(30000) | Out-Null
Start-Sleep 2

Anotar "`n== Después de instalar con el asistente"
Comprobar 'el .exe está instalado' (Test-Path $exe)
Comprobar 'el atajo quedó corriendo' (Corriendo)
Comprobar 'el arranque con Windows viene tildado: hay acceso directo en Inicio' (Test-Path $lnkInicio)
Comprobar 'hay acceso directo en el menú Inicio' (Test-Path $lnkMenu)
$destino = (New-Object -ComObject WScript.Shell).CreateShortcut($lnkInicio).TargetPath
Comprobar 'el acceso directo de Inicio apunta al .exe' ($destino -eq $exe)
Comprobar 'figura en Aplicaciones instaladas' (Test-Path $uninstallKey)
Comprobar 'no hay diálogos de error del atajo' (-not (Ventana '*' 'PincelIllustrator*' 1))
Comprobar 'al terminar de instalar no se abre sola la ventana de ajustes' (-not (Ventana '*' $nombre 2))

Anotar "`n== Ventana de ajustes"
function AbrirDesdeBandeja {
    # Mensaje que el ícono de la bandeja le manda al atajo con doble clic
    [W]::PostMessageW([W]::FindWindowW('AutoHotkey', [NullString]::Value), 0x404, [IntPtr]0x404, [IntPtr]0x203) | Out-Null
    return (Ventana '*' $nombre 8)
}
function Controles($v, $clase) { @([W]::Hijos($v) | Where-Object { [W]::Clase($_) -match $clase }) }
function Posicion($h) { [W]::Enviar($h, 0x400, 0, 0) }              # TBM_GETPOS
function Elegida($h) { [W]::Enviar($h, 0x147, 0, 0) }               # CB_GETCURSEL
$v = AbrirDesdeBandeja
Comprobar 'el doble clic en el ícono abre los ajustes' $v
if (-not $v) { throw 'no se abrió la ventana de ajustes' }
Start-Sleep 1
Captura '7-ajustes'
$des = Controles $v 'trackbar'; $lis = Controles $v 'ComboBox'
Comprobar 'hay tres velocidades y tres teclas' ($des.Count -eq 3 -and $lis.Count -eq 3)
Comprobar 'las velocidades arrancan en el valor de fábrica' (((Posicion $des[0]) -eq 50) -and ((Posicion $des[1]) -eq 50) -and ((Posicion $des[2]) -eq 50))
$indice0 = Elegida $lis[0]
[void][W]::Enviar($lis[0], 0x14E, (Elegida $lis[1]), 0)             # CB_SETCURSEL: la misma tecla en dos acciones
Tocar $v 'Guardar'
$aviso = Ventana '#32770' '*' 4
Comprobar 'no deja guardar la misma tecla para dos acciones' ($aviso -and -not (Test-Path $ini))
Captura '8-teclas-repetidas'
[W]::PostMessageW($aviso, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
Start-Sleep 1
[void][W]::Enviar($lis[0], 0x14E, 3, 0)                             # Espacio
[void][W]::Enviar($des[0], 0x405, 1, 80)                            # TBM_SETPOS
Tocar $v 'Guardar'
Start-Sleep 1
Comprobar 'guardar cierra la ventana' (-not (Ventana '*' $nombre 2))
$contenido = Get-Content $ini
Comprobar 'guardó la velocidad' ($contenido -match '=80$')
Comprobar 'guardó la tecla' ($contenido -match '=Space$')

Anotar "`n== Si lo cierran sin querer"
Stop-Process -Name PincelIllustrator -Force
Start-Sleep 1
Start-Process $lnkMenu
$v = Ventana '*' $nombre 8
Comprobar 'abrirlo desde el menú Inicio muestra los ajustes' $v
Comprobar 'y queda corriendo' (Corriendo)
if ($v) {
    Comprobar 'conserva la velocidad guardada' ((Posicion (Controles $v 'trackbar')[0]) -eq 80)
    Comprobar 'conserva la tecla guardada' ((Elegida (Controles $v 'ComboBox')[0]) -eq 3)
    Tocar $v 'Cancelar'
    Start-Sleep 1
}
Comprobar 'cerrar los ajustes no cierra el atajo' (Corriendo)

Anotar "`n== Un archivo de ajustes roto no rompe el atajo"
Stop-Process -Name PincelIllustrator -Force
Start-Sleep 1
Set-Content $ini "[Sensibilidad]`nLibre=hola`nUnPaso=999`n[Teclas]`nTeclaUnPaso=Shift`nTeclaMedioPaso=a`nTeclaUnidad=a"
Start-Process $exe
$v = Ventana '*' $nombre 8
Comprobar 'arranca igual' ((Corriendo) -and $v)
Comprobar 'sin diálogos de error' (-not (Ventana '*' 'PincelIllustrator*' 1))
if ($v) {
    Comprobar 'vuelve a los valores de fábrica' ((Posicion (Controles $v 'trackbar')[0]) -eq 50)
    Tocar $v 'Guardar'
    Start-Sleep 1
}

Anotar "`n== Arranque: el acceso directo de Inicio levanta el atajo"
Stop-Process -Name PincelIllustrator -Force
Start-Sleep 1
Comprobar 'cerrado antes de probar' (-not (Corriendo))
Start-Process $lnkInicio
Start-Sleep 3
Comprobar 'el acceso directo lo arranca' (Corriendo)
Comprobar 'sin abrir los ajustes' (-not (Ventana '*' $nombre 2))

Anotar "`n== Actualizar encima, sin arranque y con el atajo corriendo"
$antes = (Get-Process PincelIllustrator).Id
$codigo = Instalar @('/TASKS=""')
Comprobar "el instalador termina bien (código $codigo)" ($codigo -eq 0)
Comprobar 'desaparece el acceso directo de Inicio' (-not (Test-Path $lnkInicio))
Comprobar 'el .exe corre de nuevo y es otro proceso' ((Corriendo) -and (Get-Process PincelIllustrator).Id -ne $antes)
Comprobar 'una sola copia corriendo' (@(Get-Process PincelIllustrator).Count -eq 1)
Comprobar 'actualizar conserva los ajustes guardados' (Test-Path $ini)

Anotar "`n== Volver a activar el arranque"
$codigo = Instalar @('/TASKS="arranque"')
Comprobar "el instalador termina bien (código $codigo)" ($codigo -eq 0)
Comprobar 'vuelve el acceso directo de Inicio' (Test-Path $lnkInicio)

Anotar "`n== Desinstalar con el atajo corriendo"
Comprobar 'está corriendo antes de desinstalar' (Corriendo)
$codigo = Desinstalar
Comprobar "el desinstalador termina bien (código $codigo)" ($codigo -eq 0)
Comprobar 'el atajo ya no corre' (-not (Corriendo))
Comprobar 'no queda el archivo de ajustes' (-not (Test-Path $ini))
Comprobar 'no queda la carpeta instalada' (-not (Test-Path $app))
Comprobar 'no queda el acceso directo de Inicio' (-not (Test-Path $lnkInicio))
Comprobar 'no queda el acceso directo del menú' (-not (Test-Path $lnkMenu))
Comprobar 'no figura en Aplicaciones instaladas' (-not (Test-Path $uninstallKey))
$diferencias = Compare-Object $fotoAntes (Foto)
Comprobar 'archivos y registro iguales a los de antes de instalar' (-not $diferencias)
$diferencias | ForEach-Object { Anotar "      $($_.SideIndicator) $($_.InputObject)" }

Anotar "`n== Desinstalar con el arranque apagado"
Instalar @('/TASKS=""') | Out-Null
Stop-Process -Name PincelIllustrator -Force -ErrorAction SilentlyContinue
$codigo = Desinstalar
Comprobar "el desinstalador termina bien (código $codigo)" ($codigo -eq 0)
$diferencias = Compare-Object $fotoAntes (Foto)
Comprobar 'tampoco queda nada' (-not (Test-Path $app) -and -not $diferencias)
$diferencias | ForEach-Object { Anotar "      $($_.SideIndicator) $($_.InputObject)" }
if (Test-Path $app) { Get-ChildItem $app -Force | ForEach-Object { Anotar "      queda en la carpeta: $($_.Name)" } }

[W]::NoResponden | ForEach-Object { Anotar $_ }
Comprobar 'el atajo nunca dejó de responder' (-not ([W]::NoResponden -match 'PincelIllustrator'))
Anotar "`nFALLAS: $script:fallos"
'terminado' | Set-Content "$Resultados\terminado.txt"
