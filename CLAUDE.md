# Illustrator: atajo de pincel

Shift + Alt + mover el mouse cambia el tamaño del pincel en Illustrator, con un círculo rojo a escala real, como Alt + clic derecho en Photoshop. El público son personas que usan Illustrator y no saben programar: instalar tiene que ser bajar un `.exe` y seguir el asistente.

## Objetivo actual

Instalador `.exe` guiado, publicado en GitHub Releases. Está terminado cuando, en una PC sin AutoHotkey, el instalador deja el atajo funcionando y arrancando con Windows, y el desinstalador borra todo lo que puso. La lista de cosas que toca en la PC está abajo: cada una tiene que tener su instalación y su desinstalación.

## Qué toca en la PC

- **El programa**: `%LOCALAPPDATA%\Programs\Atajo de pincel para Illustrator\`, con `PincelIllustrator.exe`, `pincel.ini` y las licencias. El desinstalador cierra el proceso y borra la carpeta.
- **Inicio de Windows** (opcional): un acceso directo en `shell:startup`. Reinstalar con la opción destildada lo saca.
- **Menú Inicio**: un acceso directo.
- **Aplicaciones instaladas**: la clave de desinstalación en `HKCU`, que crea Inno Setup.

No se instala AutoHotkey ni se toca el script suelto de `Documents\AutoHotkey`. El instalador cierra el atajo por el nombre `PincelIllustrator.exe`, nunca por `AutoHotkey64.exe`: la persona puede tener otros scripts corriendo.

## Compilar y publicar

- `instalador\compilar.ps1` instala lo que falte (versiones fijas con SHA-256) y deja el instalador en `dist\`. El `.iss` y los `.ps1` van en UTF-8 con BOM, o se rompen los acentos.
- Cada push compila en Actions. Solo un tag `vX.Y.Z` crea la Release.

## Decisiones de diseño

- Compilar con **Ahk2Exe** a un `.exe` autónomo, así la otra persona no necesita instalar AutoHotkey. Elimina el primer punto de la lista.
- Asistente con **Inno Setup**, instalación por usuario y sin permisos de administrador.
- Compilar en **GitHub Actions** al crear un tag y adjuntar el instalador a la Release, para que cualquiera pueda ver de qué código sale.
- El instalador sale sin firma digital: Windows SmartScreen va a avisar. El README explica cómo seguir ("Más información" → "Ejecutar de todos modos").
- Licencia MIT.

## Lo que el script da por hecho

- `PINCEL_PT` es el tamaño del pincel: el grosor real es `PINCEL_PT` × Stroke, y el círculo sale de esa cuenta. Con otro pincel el círculo no coincide con la línea. Se elige en el asistente junto con `MAXIMO_PT` y se cambia desde el ícono de la bandeja; los dos se guardan en `pincel.ini`, junto al `.exe`.
- Habla con Illustrator por COM (`ComObjActive("Illustrator.Application")` + `DoJavaScript`), y necesita un documento abierto. Si Illustrator corre como administrador y el atajo no, COM falla y el script no avisa: está en la sección de problemas del README.
- Detecta Illustrator por `ahk_exe Illustrator.exe`, que no depende de la versión.

## Pruebas

- `AutoHotkey64.exe /ErrorStdOut /Validate pincel-illustrator.ahk` valida la sintaxis.
- El gesto real (Shift + Alt apretados, en Illustrator) solo lo puede probar una persona: pedir esa prueba y no darlo por probado sin ella.
- Instalar y desinstalar: `pruebas\probar-en-sandbox.ps1` lo prueba en Windows Sandbox, que arranca limpio y sin AutoHotkey, y deja informe y capturas en `build\sandbox\`. Illustrator no está ahí, así que cubre instalación, arranque y desinstalación, no el gesto.
