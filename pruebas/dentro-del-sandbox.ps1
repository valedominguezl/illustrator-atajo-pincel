# Corre dentro de Windows Sandbox (lo lanza probar-en-sandbox.ps1). Prueba el instalador de punta a punta y deja
# en la carpeta de resultados un informe y capturas de cada página del asistente. El gesto en Illustrator no se prueba acá.
param([string]$Instalador, [string]$Resultados)

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Windows.Forms, System.Drawing
$nombre = 'Atajo de pincel para Illustrator'
$app = "$env:LOCALAPPDATA\Programs\$nombre"
$exe = "$app\PincelIllustrator.exe"
$ini = "$app\pincel.ini"
$lnkInicio = "$([Environment]::GetFolderPath('Startup'))\$nombre.lnk"
$lnkMenu = "$([Environment]::GetFolderPath('Programs'))\$nombre.lnk"
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{5E34864E-8941-4C6D-951E-7877ECFA8A73}_is1'
$informe = "$Resultados\informe.txt"
$script:fallos = 0

function Anotar($texto) { $texto | Tee-Object -FilePath $informe -Append | Out-Host }
function Comprobar($descripcion, $condicion) {
    if ($condicion) { Anotar "OK    $descripcion" } else { Anotar "FALLA $descripcion"; $script:fallos++ }
}
function Corriendo { [bool](Get-Process PincelIllustrator -ErrorAction SilentlyContinue) }
function Instalar([string[]]$argumentos) {
    $p = Start-Process $Instalador -ArgumentList (@('/VERYSILENT', '/SUPPRESSMSGBOXES') + $argumentos) -Wait -PassThru
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
    $general = reg query HKCU /f 'pincel' /s /k 2>$null | Where-Object { $_ -match '^HKEY' }
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
$raiz = [Windows.Automation.AutomationElement]::RootElement
function Buscar($elemento, $tipo, $texto) {
    $c = New-Object Windows.Automation.PropertyCondition ([Windows.Automation.AutomationElement]::ControlTypeProperty), $tipo
    foreach ($e in $elemento.FindAll([Windows.Automation.TreeScope]::Descendants, $c)) {
        if (-not $texto -or $e.Current.Name -like $texto) { return $e }
    }
}
function Ventana($titulo, $segundos = 20) {
    $c = New-Object Windows.Automation.PropertyCondition ([Windows.Automation.AutomationElement]::NameProperty), $titulo
    for ($i = 0; $i -lt $segundos * 4; $i++) {
        foreach ($v in $raiz.FindAll([Windows.Automation.TreeScope]::Children, [Windows.Automation.Condition]::TrueCondition)) {
            if ($v.Current.Name -like $titulo) { return $v }
        }
        Start-Sleep -Milliseconds 250
    }
}
function Tocar($ventana, $texto) {
    $b = Buscar $ventana ([Windows.Automation.ControlType]::Button) $texto
    if (-not $b) { throw "No está el botón '$texto'" }
    $b.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
    Start-Sleep -Milliseconds 700
}
function Campos($ventana) {
    $c = New-Object Windows.Automation.PropertyCondition ([Windows.Automation.AutomationElement]::ControlTypeProperty), ([Windows.Automation.ControlType]::Edit)
    return @($ventana.FindAll([Windows.Automation.TreeScope]::Descendants, $c))
}
function Escribir($campo, $valor) { $campo.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).SetValue($valor) }
function Leer($campo) { $campo.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).Current.Value }

Anotar "Prueba: $(Get-Date -Format s)  $Instalador  SHA-256 $((Get-FileHash $Instalador).Hash)"

Anotar "`n== PC limpia"
Comprobar 'sin AutoHotkey instalado' (-not (Get-Command AutoHotkey64 -ErrorAction SilentlyContinue) -and -not (Test-Path "$env:ProgramFiles\AutoHotkey") -and -not (Test-Path "$env:LOCALAPPDATA\Programs\AutoHotkey"))
$fotoAntes = Foto

Anotar "`n== Asistente: valores por defecto, validación y elección"
$proceso = Start-Process $Instalador -PassThru
$w = Ventana 'Instalar*'
if (-not $w) { $w = Ventana '*Atajo de pincel*' }
Start-Sleep 1
Captura '1-bienvenida'
Tocar $w 'Siguiente*'
$campos = Campos $w
Comprobar 'la página de pincel propone 5 y 400' ((Leer $campos[0]) -eq '5' -and (Leer $campos[1]) -eq '400')
Captura '2-pincel'
Escribir $campos[0] 'abc'
Tocar $w 'Siguiente*'
Start-Sleep 1
Captura '3-error-validacion'
[Windows.Forms.SendKeys]::SendWait('{ENTER}')
Start-Sleep 1
$campos = Campos $w
Comprobar 'un tamaño inválido no deja avanzar' ($campos.Count -ge 2 -and (Leer $campos[0]) -eq 'abc')
Escribir $campos[0] '7,5'
Escribir $campos[1] '300'
Tocar $w 'Siguiente*'
Captura '4-tareas'
$tilde = Buscar $w ([Windows.Automation.ControlType]::CheckBox) 'Arrancar*'
Comprobar 'la opción de arrancar con Windows viene tildada' ($tilde -and $tilde.GetCurrentPattern([Windows.Automation.TogglePattern]::Pattern).Current.ToggleState -eq 'On')
Tocar $w 'Siguiente*'
Captura '5-listo'
Tocar $w 'Instalar*'
Start-Sleep 4
Captura '6-fin'
Tocar $w 'Finalizar*'
$proceso.WaitForExit(30000) | Out-Null
Start-Sleep 2

Anotar "`n== Después de instalar con el asistente"
Comprobar 'el .exe está instalado' (Test-Path $exe)
Comprobar 'el atajo quedó corriendo' (Corriendo)
Comprobar 'se guardó el pincel elegido con punto decimal (7.5)' ((Get-Content $ini) -contains 'PincelPt=7.5')
Comprobar 'se guardó el máximo elegido (300)' ((Get-Content $ini) -contains 'MaximoPt=300')
Comprobar 'hay acceso directo en Inicio de Windows' (Test-Path $lnkInicio)
Comprobar 'hay acceso directo en el menú Inicio' (Test-Path $lnkMenu)
$destino = (New-Object -ComObject WScript.Shell).CreateShortcut($lnkInicio).TargetPath
Comprobar 'el acceso directo de Inicio apunta al .exe' ($destino -eq $exe)
Comprobar 'figura en Aplicaciones instaladas' (Test-Path $uninstallKey)
Comprobar 'no hay diálogos de error del atajo' (-not (Ventana 'PincelIllustrator*' 1))

Anotar "`n== El .exe lee el .ini y se puede cambiar desde la bandeja"
Add-Type -Namespace Win -Name Api -MemberDefinition '[DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr FindWindowW(string c, string t); [DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);'
# Mensaje que el ícono de la bandeja le manda al atajo con doble clic (el tray no se puede tocar por automatización)
$oculta = [Win.Api]::FindWindowW('AutoHotkey', $null)
[Win.Api]::PostMessageW($oculta, 0x404, [IntPtr]::Zero, [IntPtr]0x203) | Out-Null
$v = Ventana 'Atajo de pincel' 8
Comprobar 'el doble clic abre el pedido de tamaño' ($v)
if ($v) {
    Comprobar 'muestra el 7.5 que leyó del .ini' ((Leer (Campos $v)[0]) -eq '7.5')
    Start-Sleep 1
    Captura '7-bandeja'
    Escribir (Campos $v)[0] '9,25'
    Tocar $v 'OK'
    $v = Ventana 'Atajo de pincel' 5
    Comprobar 'muestra el 300 que leyó del .ini' ((Leer (Campos $v)[0]) -eq '300')
    Tocar $v 'OK'
    Start-Sleep 1
    Comprobar 'guardó el cambio con punto decimal (9.25)' ((Get-Content $ini) -match 'PincelPt=9.25')
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

Anotar "`n== Volver a activar el arranque por instalación silenciosa con valores"
$codigo = Instalar @('/TASKS="arranque"', '/PINCEL=3', '/MAXIMO=120')
Comprobar "el instalador termina bien (código $codigo)" ($codigo -eq 0)
Comprobar 'vuelve el acceso directo de Inicio' (Test-Path $lnkInicio)
Comprobar 'toma el pincel pasado (3)' ((Get-Content $ini) -match 'PincelPt=3$')

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

Anotar "`n== Desinstalar con el .ini reescrito y el arranque apagado"
Instalar @('/TASKS=""') | Out-Null
Stop-Process -Name PincelIllustrator -Force -ErrorAction SilentlyContinue
Add-Content $ini 'Extra=1'
$codigo = Desinstalar
Comprobar "el desinstalador termina bien (código $codigo)" ($codigo -eq 0)
Comprobar 'tampoco queda nada' (-not (Test-Path $app) -and -not (Compare-Object $fotoAntes (Foto)))

Anotar "`nFALLAS: $script:fallos"
'terminado' | Set-Content "$Resultados\terminado.txt"
