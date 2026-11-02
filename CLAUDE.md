# Illustrator: atajo de pincel

Shift + Alt + mover el mouse cambia el tamaño del pincel en Illustrator, viendo el círculo de vista previa del propio Illustrator, como Alt + clic derecho en Photoshop. Sumando Ctrl va de a 1 y sumando Espacio de a 0,5, en la unidad del Stroke. El público son personas que usan Illustrator y no saben programar: instalar tiene que ser bajar un `.exe` y seguir el asistente.

## Objetivo actual

Instalador `.exe` guiado, publicado en GitHub Releases. Está terminado cuando, en una PC sin AutoHotkey, el instalador deja el atajo funcionando y arrancando con Windows, y el desinstalador borra todo lo que puso. La lista de cosas que toca en la PC está abajo: cada una tiene que tener su instalación y su desinstalación.

## Qué toca en la PC

- **El programa**: `%LOCALAPPDATA%\Programs\Atajo de pincel para Illustrator\`, con `PincelIllustrator.exe` y las licencias. El desinstalador cierra el proceso y borra la carpeta.
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

- No necesita saber qué pincel está elegido: cambia `defaultStrokeWidth` y el círculo de vista previa de Illustrator se actualiza solo (comprobado en Illustrator 2026, sin mover el mouse). Si Alt llega a Illustrator, activa el suavizar y esconde ese círculo: por eso el script bloquea Shift, Alt, Ctrl y Espacio mientras ajusta, y esas teclas solo se sueltan cuando se soltó todo.
- Alt primero no alcanza a evitar el suavizar: Illustrator ya recibió Alt. El gesto correcto es Shift y después Alt.
- Windows cambia el idioma si ve Alt y Shift juntos: el script nunca deja que los dos estén apretados a la vez para el sistema.
- El cursor queda quieto con `BlockInput "MouseMove"` y el movimiento se lee por Raw Input (`WM_INPUT`). Devolverlo a su lugar con `SetCursorPos` lo hacía temblar.
- Lo que no sirve para leer el pincel elegido: su ventana no expone controles por UI Automation y una línea creada por script no toma el pincel. El círculo lo dibuja Illustrator en el lienzo, no es un cursor de Windows.
- Habla con Illustrator por COM (`ComObjActive("Illustrator.Application")` + `DoJavaScript`), y necesita un documento abierto. Si Illustrator corre como administrador y el atajo no, COM falla y el script no avisa: está en la sección de problemas del README.
- Ctrl y Espacio van de a 1 y 0,5 en la unidad de la preferencia `strokeUnits` de Illustrator, que comparten el pincel y las demás herramientas. `defaultStrokeWidth` siempre es en pt. El tope `MAXIMO_STROKE` es de 400 pt sobre el Stroke, no sobre el grosor final, que depende del pincel.
- Detecta Illustrator por `ahk_exe Illustrator.exe` y su ventana principal por `ahk_class illustrator`, para no actuar con un diálogo abierto. La clase solo se comprobó en Illustrator 2026.
- Si una tecla queda bloqueada a medias, Windows la cree apretada y Illustrator se traba (Ctrl trabado hace que Esc abra Inicio). Toda salida de `Ajustar` tiene que dejar soltadas Shift, Alt, Ctrl y Espacio. Para diagnosticar: crear `%TEMP%\pincel-atajo.log` vacío y el atajo registra ahí cada gesto.

## Pruebas

- `AutoHotkey64.exe /ErrorStdOut /Validate pincel-illustrator.ahk` valida la sintaxis.
- El gesto real (Shift + Alt apretados, en Illustrator) solo lo puede probar una persona: pedir esa prueba y no darlo por probado sin ella.
- Instalar y desinstalar: `pruebas\probar-en-sandbox.ps1` lo prueba en Windows Sandbox, que arranca limpio y sin AutoHotkey, y deja informe y capturas en `build\sandbox\`. Illustrator no está ahí, así que cubre instalación, arranque y desinstalación, no el gesto.
