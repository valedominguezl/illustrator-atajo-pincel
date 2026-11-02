# Abre Windows Sandbox (limpio y sin AutoHotkey), corre dentro-del-sandbox.ps1 con el instalador y espera el informe.
# Requiere la característica de Windows «Espacio aislado de Windows». Por defecto prueba dist\Instalar-Atajo-de-Pincel.exe.
param(
    [string]$Instalador = "$(Split-Path $PSScriptRoot)\dist\Instalar-Atajo-de-Pincel.exe",
    [string]$Resultados = "$(Split-Path $PSScriptRoot)\build\sandbox",
    [int]$MinutosMaximo = 10
)

$ErrorActionPreference = 'Stop'
$Instalador = (Resolve-Path $Instalador).Path
if (Test-Path $Resultados) { Remove-Item $Resultados -Recurse -Force }
New-Item -ItemType Directory $Resultados | Out-Null

# Dentro del Sandbox el instalador y las pruebas son de solo lectura; solo se puede escribir en los resultados
$base = Split-Path $Instalador
$nombreInstalador = Split-Path $Instalador -Leaf
$wsb = "$Resultados\prueba.wsb"
@"
<Configuration>
  <Networking>Disable</Networking>
  <vGPU>Disable</vGPU>
  <MappedFolders>
    <MappedFolder><HostFolder>$base</HostFolder><SandboxFolder>C:\Prueba\instalador</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder>
    <MappedFolder><HostFolder>$PSScriptRoot</HostFolder><SandboxFolder>C:\Prueba\scripts</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder>
    <MappedFolder><HostFolder>$Resultados</HostFolder><SandboxFolder>C:\Prueba\resultados</SandboxFolder><ReadOnly>false</ReadOnly></MappedFolder>
  </MappedFolders>
  <LogonCommand>
    <Command>powershell -NoProfile -ExecutionPolicy Bypass -File C:\Prueba\scripts\dentro-del-sandbox.ps1 -Instalador C:\Prueba\instalador\$nombreInstalador -Resultados C:\Prueba\resultados</Command>
  </LogonCommand>
</Configuration>
"@ | Set-Content $wsb -Encoding UTF8

Start-Process "$env:WINDIR\System32\WindowsSandbox.exe" -ArgumentList "`"$wsb`""
$limite = (Get-Date).AddMinutes($MinutosMaximo)
while (-not (Test-Path "$Resultados\terminado.txt")) {
    if ((Get-Date) -gt $limite) { throw "El Sandbox no terminó en $MinutosMaximo minutos. Ver $Resultados" }
    Start-Sleep 5
}
Get-Content "$Resultados\informe.txt"
if ((Get-Content "$Resultados\informe.txt") -notcontains 'FALLAS: 0') { exit 1 }
