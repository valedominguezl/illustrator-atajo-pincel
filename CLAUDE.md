# Illustrator: atajo de pincel

Shift + Alt + mover el mouse cambia el tamaño del pincel en Illustrator, con un círculo rojo a escala real, como Alt + clic derecho en Photoshop. El público son personas que usan Illustrator y no saben programar: instalar tiene que ser bajar un `.exe` y seguir el asistente.

## Objetivo actual

Instalador `.exe` guiado, publicado en GitHub Releases. Está terminado cuando, en una PC sin AutoHotkey, el instalador deja el atajo funcionando y arrancando con Windows, y el desinstalador borra todo lo que puso. La lista de cosas que toca en la PC está abajo: cada una tiene que tener su instalación y su desinstalación.

## Qué toca en la PC

- **AutoHotkey v2**: hoy se instala aparte con `winget install AutoHotkey.AutoHotkey`.
- **El script**: `%USERPROFILE%\Documents\AutoHotkey\pincel-illustrator.ahk`.
- **Inicio de Windows**: un acceso directo en `shell:startup` para que arranque con la sesión.

## Decisiones de diseño

- Compilar con **Ahk2Exe** a un `.exe` autónomo, así la otra persona no necesita instalar AutoHotkey. Elimina el primer punto de la lista.
- Asistente con **Inno Setup**, instalación por usuario y sin permisos de administrador.
- Compilar en **GitHub Actions** al crear un tag y adjuntar el instalador a la Release, para que cualquiera pueda ver de qué código sale.
- El instalador sale sin firma digital: Windows SmartScreen va a avisar. El README explica cómo seguir ("Más información" → "Ejecutar de todos modos").
- Licencia MIT.

## Lo que el script da por hecho

- `PINCEL_PT := 5` está fijo para el pincel «5 pt. Round»: el grosor real es `PINCEL_PT` × Stroke, y el círculo sale de esa cuenta. Con otro pincel el círculo no coincide con la línea. Pasarlo a un valor que se elija en el asistente y se pueda cambiar después (un `.ini` junto al `.exe` compilado). Lo mismo con `MAXIMO_PT`.
- Habla con Illustrator por COM (`ComObjActive("Illustrator.Application")` + `DoJavaScript`), y necesita un documento abierto. Si Illustrator corre como administrador y el atajo no, COM falla y el script no avisa: cubrirlo en la sección de problemas del README.
- Detecta Illustrator por `ahk_exe Illustrator.exe`, que no depende de la versión.

## Pruebas

- `AutoHotkey64.exe /ErrorStdOut /Validate pincel-illustrator.ahk` valida la sintaxis.
- El gesto real (Shift + Alt apretados, en Illustrator) solo lo puede probar una persona: pedir esa prueba y no darlo por probado sin ella.
- Instalar y desinstalar: probarlo en Windows Sandbox, que arranca limpio y sin AutoHotkey. Illustrator no está ahí, así que cubre instalación, arranque y desinstalación, no el gesto.
