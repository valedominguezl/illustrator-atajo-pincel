; Instalador del atajo de pincel. Se compila con instalador\compilar.ps1, que primero genera build\PincelIllustrator.exe.
; Instalación silenciosa: /VERYSILENT /TASKS="arranque" (o /TASKS="") /PINCEL=5 /MAXIMO=400

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
FinishedLabel=Ya está instalado.%n%nAbrí un documento en Illustrator, mantené Shift + Alt y mové el mouse sin hacer clic: a la derecha agranda, a la izquierda achica.%n%nPara cambiar el tamaño de tu pincel más adelante, hacé doble clic en el ícono verde con una H, junto al reloj de Windows.

[Tasks]
Name: "arranque"; Description: "Arrancar el atajo con Windows (recomendado)"

[InstallDelete]
; Si en una reinstalación se destilda la opción, el acceso directo anterior no puede quedar
Type: files; Name: "{userstartup}\{#Nombre}.lnk"; Tasks: not arranque

[Files]
Source: "..\build\{#Exe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; DestName: "LICENCIA.txt"; Flags: ignoreversion
Source: "..\licencias\AutoHotkey-GPLv2.txt"; DestDir: "{app}"; DestName: "LICENCIA-AutoHotkey.txt"; Flags: ignoreversion

[INI]
Filename: "{app}\pincel.ini"; Section: "Pincel"; Key: "PincelPt"; String: "{code:ValorPincel}"
Filename: "{app}\pincel.ini"; Section: "Pincel"; Key: "MaximoPt"; String: "{code:ValorMaximo}"

[Icons]
Name: "{autoprograms}\{#Nombre}"; Filename: "{app}\{#Exe}"
Name: "{userstartup}\{#Nombre}"; Filename: "{app}\{#Exe}"; Tasks: arranque

[Run]
Filename: "{app}\{#Exe}"; Description: "Activar el atajo ahora"; Flags: nowait postinstall

[UninstallDelete]
; El atajo puede haberlo reescrito desde la bandeja: se borra aunque haya cambiado
Type: files; Name: "{app}\pincel.ini"

[Code]
var
  PaginaPincel: TInputQueryWizardPage;

// Pasa 5, 5.5 o 5,5 a centésimas, sin depender de la configuración regional de la PC.
function Centesimas(Texto: String; var Valor: Integer): Boolean;
var
  I, Decimales: Integer;
  VioSeparador: Boolean;
begin
  Result := False;
  Valor := 0;
  Decimales := 0;
  VioSeparador := False;
  Texto := Trim(Texto);
  if (Texto = '') or (Length(Texto) > 7) then
    Exit;
  for I := 1 to Length(Texto) do
    if (Texto[I] = '.') or (Texto[I] = ',') then
    begin
      if VioSeparador or (I = 1) or (I = Length(Texto)) then
        Exit;
      VioSeparador := True;
    end
    else if (Texto[I] >= '0') and (Texto[I] <= '9') then
    begin
      Valor := Valor * 10 + Ord(Texto[I]) - Ord('0');
      if VioSeparador then
      begin
        Decimales := Decimales + 1;
        if Decimales > 2 then
          Exit;
      end;
    end
    else
      Exit;
  while Decimales < 2 do
  begin
    Valor := Valor * 10;
    Decimales := Decimales + 1;
  end;
  Result := True;
end;

function ConPunto(Texto: String): String;
begin
  Result := Trim(Texto);
  StringChangeEx(Result, ',', '.', True);
end;

function ValorPincel(Param: String): String;
begin
  Result := ConPunto(PaginaPincel.Values[0]);
end;

function ValorMaximo(Param: String): String;
begin
  Result := ConPunto(PaginaPincel.Values[1]);
end;

procedure InitializeWizard;
var
  Ini: String;
begin
  PaginaPincel := CreateInputQueryPage(wpWelcome, 'Tu pincel',
    '¿Con qué pincel dibujás?',
    'Fijate en el panel Pinceles de Illustrator: el número del nombre es su tamaño (el pincel «5 pt. Round» es 5). ' +
    'Para que el círculo rojo coincida con la línea, tiene que ser el mismo. Si usás el Lápiz, poné 1.' + #13#10 +
    'Lo podés cambiar después desde el ícono del atajo, junto al reloj.');
  PaginaPincel.Add('Tamaño de tu pincel (pt), de 0,1 a 1000:', False);
  PaginaPincel.Add('Grosor máximo de la línea (pt), hasta 5000:', False);
  // En una actualización se conserva lo que la persona ya tenía
  Ini := WizardDirValue + '\pincel.ini';
  PaginaPincel.Values[0] := ExpandConstant('{param:PINCEL|' + GetIniString('Pincel', 'PincelPt', '5', Ini) + '}');
  PaginaPincel.Values[1] := ExpandConstant('{param:MAXIMO|' + GetIniString('Pincel', 'MaximoPt', '400', Ini) + '}');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Pincel, Maximo: Integer;
begin
  Result := True;
  if CurPageID <> PaginaPincel.ID then
    Exit;
  if not Centesimas(PaginaPincel.Values[0], Pincel) or (Pincel < 10) or (Pincel > 100000) then
  begin
    MsgBox('El tamaño del pincel tiene que ser un número entre 0,1 y 1000.', mbError, MB_OK);
    Result := False;
  end
  else if not Centesimas(PaginaPincel.Values[1], Maximo) or (Maximo < Pincel) or (Maximo > 500000) then
  begin
    MsgBox('El grosor máximo tiene que ser un número entre el tamaño del pincel y 5000.', mbError, MB_OK);
    Result := False;
  end;
end;

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
