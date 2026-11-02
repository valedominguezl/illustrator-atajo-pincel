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
    [DllImport("user32", CharSet = CharSet.Unicode)] static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, StringBuilder s);
    [DllImport("user32", CharSet = CharSet.Unicode, EntryPoint = "SendMessageW")] static extern IntPtr SendTexto(IntPtr h, uint m, IntPtr w, string s);
    [DllImport("user32")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowW(string c, string t);
    public static string Clase(IntPtr h) { var s = new StringBuilder(256); GetClassNameW(h, s, 256); return s.ToString(); }
    public static string Texto(IntPtr h) { var s = new StringBuilder(4096); SendMessageW(h, 0x0D, (IntPtr)4096, s); return s.ToString(); }
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
$ini = "$app\pincel.ini"
$lnkInicio = "$([Environment]::GetFolderPath('Startup'))\$nombre.lnk"
$lnkMenu = "$([Environment]::GetFolderPath('Programs'))\$nombre.lnk"
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
Comprobar 'el asistente no pregunta el tamaño del pincel' ((Campos $w).Count -eq 0)
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

Anotar "`n== Los valores de fábrica se cambian desde la bandeja y sobreviven al reinicio del atajo"
# Mensaje que el ícono de la bandeja le manda al atajo con doble clic
$oculta = [W]::FindWindowW('AutoHotkey', [NullString]::Value)
Anotar "      ventana oculta del atajo: $oculta '$([W]::Texto($oculta))'"
[W]::PostMessageW($oculta, 0x404, [IntPtr]0x404, [IntPtr]0x203) | Out-Null
$v = Ventana '*' 'Atajo de pincel' 8
Comprobar 'el doble clic abre el pedido de tamaño' $v
if (-not $v) {
    Captura '7-sin-pedido'
    foreach ($x in [W]::Superiores()) { Anotar "      [$([W]::Clase($x))] $([W]::Texto($x))" }
}
if ($v) {
    Comprobar 'propone el pincel de fábrica (5)' ([W]::Texto((Campos $v)[0]) -eq '5')
    Captura '7-bandeja'
    [W]::PonerTexto((Campos $v)[0], '9,25')
    Tocar $v 'OK'
    $v = Ventana '*' 'Atajo de pincel' 5
    Comprobar 'propone el máximo de fábrica (400)' ([W]::Texto((Campos $v)[0]) -eq '400')
    Tocar $v 'OK'
    Start-Sleep 1
    Comprobar 'guardó el cambio con punto decimal (9.25)' ((Get-Content $ini) -match 'PincelPt=9.25')
    Stop-Process -Name PincelIllustrator -Force
    Start-Sleep 1
    Start-Process $exe
    Start-Sleep 2
    [W]::PostMessageW([W]::FindWindowW('AutoHotkey', [NullString]::Value), 0x404, [IntPtr]0x404, [IntPtr]0x203) | Out-Null
    $v = Ventana '*' 'Atajo de pincel' 8
    Comprobar 'al volver a abrir lee 9.25 del .ini' ($v -and [W]::Texto((Campos $v)[0]) -eq '9.25')
    if ($v) { Tocar $v 'Cancel' }
}

Anotar "`n== Arranque: el acceso directo de Inicio levanta el atajo"
Stop-Process -Name PincelIllustrator -Force
Start-Sleep 1
Comprobar 'cerrado antes de probar' (-not (Corriendo))
Start-Process $lnkInicio
Start-Sleep 3
Comprobar 'el acceso directo lo arranca' (Corriendo)

Anotar "`n== Actualizar encima, sin arranque y con el atajo corriendo"
$antes = (Get-Process PincelIllustrator).Id
$codigo = Instalar @('/TASKS=""')
Comprobar "el instalador termina bien (código $codigo)" ($codigo -eq 0)
Comprobar 'desaparece el acceso directo de Inicio' (-not (Test-Path $lnkInicio))
Comprobar 'conserva el tamaño cambiado (9.25)' ((Get-Content $ini) -match 'PincelPt=9.25')
Comprobar 'el .exe corre de nuevo y es otro proceso' ((Corriendo) -and (Get-Process PincelIllustrator).Id -ne $antes)
Comprobar 'una sola copia corriendo' (@(Get-Process PincelIllustrator).Count -eq 1)

Anotar "`n== Volver a activar el arranque"
$codigo = Instalar @('/TASKS="arranque"')
Comprobar "el instalador termina bien (código $codigo)" ($codigo -eq 0)
Comprobar 'vuelve el acceso directo de Inicio' (Test-Path $lnkInicio)
Comprobar 'sigue conservando el tamaño (9.25)' ((Get-Content $ini) -match 'PincelPt=9.25')

Anotar "`n== Desinstalar con el atajo corriendo"
Comprobar 'está corriendo antes de desinstalar' (Corriendo)
$codigo = Desinstalar
Comprobar "el desinstalador termina bien (código $codigo)" ($codigo -eq 0)
Comprobar 'el atajo ya no corre' (-not (Corriendo))
Comprobar 'no queda la carpeta instalada' (-not (Test-Path $app))
Comprobar 'no queda el acceso directo de Inicio' (-not (Test-Path $lnkInicio))
Comprobar 'no queda el acceso directo del menú' (-not (Test-Path $lnkMenu))
Comprobar 'no figura en Aplicaciones instaladas' (-not (Test-Path $uninstallKey))
$diferencias = Compare-Object $fotoAntes (Foto)
Comprobar 'archivos y registro iguales a los de antes de instalar' (-not $diferencias)
$diferencias | ForEach-Object { Anotar "      $($_.SideIndicator) $($_.InputObject)" }

Anotar "`n== Desinstalar sin .ini y con el arranque apagado"
Instalar @('/TASKS=""') | Out-Null
Stop-Process -Name PincelIllustrator -Force -ErrorAction SilentlyContinue
$codigo = Desinstalar
Comprobar "el desinstalador termina bien (código $codigo)" ($codigo -eq 0)
$diferencias = Compare-Object $fotoAntes (Foto)
Comprobar 'tampoco queda nada' (-not (Test-Path $app) -and -not $diferencias)
$diferencias | ForEach-Object { Anotar "      $($_.SideIndicator) $($_.InputObject)" }
if (Test-Path $app) { Get-ChildItem $app -Force | ForEach-Object { Anotar "      queda en la carpeta: $($_.Name)" } }

Anotar "`nFALLAS: $script:fallos"
'terminado' | Set-Content "$Resultados\terminado.txt"
