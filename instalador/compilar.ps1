# Compila el atajo a un .exe autónomo y arma el instalador en dist\. Sirve igual en una PC y en GitHub Actions.
# Lo que falte (AutoHotkey, Ahk2Exe, Inno Setup) se baja de su Release oficial, se verifica con SHA-256
# y se instala en la cuenta del usuario, sin permisos de administrador.
param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version = '0.0.0'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$raiz = Split-Path $PSScriptRoot
$programas = "$env:LOCALAPPDATA\Programs"
$ahk = "$programas\AutoHotkey\v2\AutoHotkey64.exe"
$ahk2exe = "$programas\AutoHotkey\Compiler\Ahk2Exe.exe"
$iscc = "$programas\Inno Setup 6\ISCC.exe"

function Descargar($url, $sha256) {
    $carpeta = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory $carpeta | Out-Null
    $archivo = Join-Path $carpeta (Split-Path $url -Leaf)
    Invoke-WebRequest $url -OutFile $archivo -UseBasicParsing
    $real = (Get-FileHash $archivo -Algorithm SHA256).Hash
    if ($real -ne $sha256) { throw "SHA-256 inesperado en $url`: $real" }
    return $archivo
}

function Ejecutar($exe, [string[]]$argumentos) {
    $p = Start-Process $exe -ArgumentList $argumentos -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "$(Split-Path $exe -Leaf) terminó con código $($p.ExitCode)" }
}

if (-not (Test-Path $ahk)) {
    Write-Host 'Instalando AutoHotkey 2.0.31 (solo el intérprete)...'
    $zip = Descargar 'https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.31/AutoHotkey_2.0.31.zip' 'CA1A595ACA4528755D8D4CD7FED23D497A37BD9A0B6892072612D68DEE1BD00A'
    Expand-Archive $zip (Split-Path $ahk) -Force
}
if (-not (Test-Path $ahk2exe)) {
    Write-Host 'Instalando Ahk2Exe 1.1.37.02a2...'
    $zip = Descargar 'https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe1.1.37.02a2/Ahk2Exe1.1.37.02a2.zip' 'C29B8C3A5124850D79FC9E66E2CA79677C377D7F31631AD3022BA159C5D9E3BE'
    Expand-Archive $zip (Split-Path $ahk2exe) -Force
}
if (-not (Test-Path $iscc)) {
    Write-Host 'Instalando Inno Setup 6.7.3...'
    $exe = Descargar 'https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe' '9C73C3BAE7ED48D44112A0F48E66742C00090BDB5BEF71D9D3C056C66E97B732'
    Ejecutar $exe @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CURRENTUSER', '/NOICONS', "/DIR=`"$(Split-Path $iscc)`"")
}

$script = "$raiz\pincel-illustrator.ahk"
$build = "$raiz\build"
New-Item -ItemType Directory $build, "$raiz\dist" -Force | Out-Null

Write-Host 'Validando el script...'
Ejecutar $ahk @('/ErrorStdOut', '/Validate', "`"$script`"")

Write-Host 'Compilando el atajo...'
Remove-Item "$build\PincelIllustrator.exe" -ErrorAction SilentlyContinue
Ejecutar $ahk2exe @('/in', "`"$script`"", '/out', "`"$build\PincelIllustrator.exe`"", '/base', "`"$ahk`"", '/silent')
if (-not (Test-Path "$build\PincelIllustrator.exe")) { throw 'Ahk2Exe no generó el .exe' }

Write-Host "Armando el instalador $Version..."
& $iscc "/DAppVersion=$Version" "$PSScriptRoot\pincel-illustrator.iss"
if ($LASTEXITCODE -ne 0) { throw "ISCC terminó con código $LASTEXITCODE" }

Get-Item "$raiz\dist\Instalar-Atajo-de-Pincel.exe" | ForEach-Object { '{0}  {1:N0} bytes  SHA-256 {2}' -f $_.FullName, $_.Length, (Get-FileHash $_.FullName).Hash }
