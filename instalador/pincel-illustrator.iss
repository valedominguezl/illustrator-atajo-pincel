; Instalador del atajo de pincel. Se compila con instalador\compilar.ps1, que primero genera build\PincelIllustrator.exe.
; Instalación silenciosa: /VERYSILENT /TASKS="arranque" (o /TASKS="")

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#define Nombre "Atajo de pincel para Illustrator"
#define Exe "PincelIllustrator.exe"

[Setup]
AppId={{5E34864E-8941-4C6D-951E-7877ECFA8A73}
AppName={#Nombre}
AppVersion={#AppVersion}
AppVerName={#Nombre} {#AppVersion}
AppPublisher=valedominguezl
AppPublisherURL=https://github.com/valedominguezl/illustrator-atajo-pincel
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#Nombre}
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableWelcomePage=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\dist
OutputBaseFilename=Instalar-Atajo-de-Pincel
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#Nombre}
UninstallDisplayIcon={app}\{#Exe}
RestartApplications=no

[Languages]
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"

[Messages]
WelcomeLabel2=Con este atajo cambiás el tamaño del pincel en Illustrator manteniendo Shift + Alt y moviendo el mouse, como en Photoshop.%n%nNo hace falta instalar nada más ni tener permisos de administrador.
FinishedLabel=Ya está instalado.%n%nAbrí un documento en Illustrator, mantené Shift + Alt y mové el mouse sin hacer clic: a la derecha agranda, a la izquierda achica.%n%nEl atajo averigua el tamaño de tu pincel midiendo tu último trazo: si cambiás de pincel, dibujá una línea con él para que el círculo rojo coincida.

[Tasks]
Name: "arranque"; Description: "Arrancar el atajo con Windows (recomendado)"

[InstallDelete]
; Si en una reinstalación se destilda la opción, el acceso directo anterior no puede quedar
Type: files; Name: "{userstartup}\{#Nombre}.lnk"; Tasks: not arranque

[Files]
Source: "..\build\{#Exe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; DestName: "LICENCIA.txt"; Flags: ignoreversion
Source: "..\licencias\AutoHotkey-GPLv2.txt"; DestDir: "{app}"; DestName: "LICENCIA-AutoHotkey.txt"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#Nombre}"; Filename: "{app}\{#Exe}"
Name: "{userstartup}\{#Nombre}"; Filename: "{app}\{#Exe}"; Tasks: arranque

[Run]
Filename: "{app}\{#Exe}"; Description: "Activar el atajo ahora"; Flags: nowait postinstall

[UninstallDelete]
; Lo escribe el atajo, no el instalador
Type: files; Name: "{app}\pincel.ini"

[Code]
// Para poder reemplazar o borrar el .exe. Va por nombre exacto: no toca otros scripts de AutoHotkey de la persona.
procedure CerrarAtajo;
var
  Codigo: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM {#Exe}', '', SW_HIDE, ewWaitUntilTerminated, Codigo);
  Sleep(500);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  CerrarAtajo;
  Result := '';
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    CerrarAtajo;
end;
