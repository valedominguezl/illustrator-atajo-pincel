# Illustrator: atajo de pincel

Cambiá el tamaño del pincel en Adobe Illustrator como en Photoshop, sin ir al panel.

Apretá **Shift**, después **Alt**, y mové el mouse sin hacer clic: a la derecha agranda, a la izquierda achica. El círculo de vista previa de Illustrator se actualiza mientras ajustás, y al lado aparece el Stroke en pt y mm.

Solo para Windows 10 u 11 de 64 bits.

## Instalar

1. **[Bajá el instalador](https://github.com/valedominguezl/illustrator-atajo-pincel/releases/latest/download/Instalar-Atajo-de-Pincel.exe)** y abrilo.
2. Si aparece «Windows protegió su PC», tocá **Más información** y después **Ejecutar de todos modos**. El aviso sale porque el instalador no tiene firma digital, un certificado pago. Más abajo explicamos de dónde sale.
3. Seguí el asistente. Solo te pregunta **si el atajo arranca con Windows**: dejalo tildado para no tener que abrirlo cada vez.

No hace falta instalar nada más ni tener permisos de administrador.

## Usar

1. Abrí un documento en Illustrator y elegí el Pincel, el Lápiz o la Pluma.
2. Apretá **Shift**, después **Alt**, y mové el mouse sin hacer clic. Si apretás primero Alt, puede aparecer el cursor de suavizar de Illustrator en lugar del círculo.
3. Soltá las teclas y dibujá: lo próximo que dibujes sale con ese grosor.

Mientras el atajo está activo, vas a ver un ícono verde con una **H** junto al reloj de Windows (a veces queda escondido bajo la flechita **^**).

## Cambiar de a poco, en valores redondos

Mientras mantenés Shift + Alt, sumá otra tecla. El cambio va más lento y cae en valores redondos del Stroke:

| Teclas | Cómo cambia el Stroke |
|---|---|
| Shift + Alt | Rápido, en proporción al tamaño |
| Shift + Alt + **Ctrl** | De a 1 |
| Shift + Alt + **Espacio** | De a 0,5 |

Los pasos van en la unidad que Illustrator usa para el Stroke, para el pincel y para cualquier otra herramienta. Si la tuya es mm, van de a 1 mm y de a 0,5 mm, sin decimales raros. La unidad se cambia en Illustrator: Edit → Preferences → Units → Stroke.

El atajo no sube el Stroke de 400 pt, aunque trabajes en otra unidad. El grosor final de la línea puede ser mayor, porque el pincel lo multiplica.

## Activar o desactivar el arranque con Windows

Volvé a abrir el instalador y tildá o destildá la opción.

Si no arranca con Windows, lo abrís cuando quieras buscando **Atajo de pincel para Illustrator** en el menú Inicio. Para cerrarlo, clic derecho en el ícono de la **H** y **Salir**.

## Desinstalar

Abrí **Configuración → Aplicaciones → Aplicaciones instaladas**, buscá **Atajo de pincel para Illustrator** y tocá **Desinstalar**. Se cierra el atajo y se borra todo lo que el instalador puso, incluido el arranque con Windows.

## Si algo no funciona

**Shift + Alt no hace nada.**
- Fijate que esté el ícono de la **H** junto al reloj. Si no está, abrí el atajo desde el menú Inicio.
- Tiene que haber un documento abierto en Illustrator y esa ventana tiene que estar al frente.
- Si abrís Illustrator como administrador, el atajo no puede hablar con él y no avisa. Abrí Illustrator de la forma normal, sin «Ejecutar como administrador». Si lo tenés configurado para abrirse siempre así, sacale esa opción en Propiedades → Compatibilidad de su acceso directo.

**No veo el círculo mientras ajusto.** Apretá Shift antes que Alt. El círculo lo dibuja Illustrator: si tu versión o tu herramienta no lo muestran, el Stroke igual cambia y podés guiarte por la medida que aparece junto al cursor.

**El número junto al cursor no coincide con el grosor de la línea.** Es normal: muestra el Stroke, y el pincel lo multiplica. Con un pincel de 3 pt y Stroke de 10 pt, la línea sale de 30 pt. El círculo sí muestra el grosor final.

**El tamaño salta el doble o el círculo parpadea.** Probablemente hay dos copias reaccionando a la vez. Pasa si antes usabas el script suelto `pincel-illustrator.ahk`: cerralo desde su ícono junto al reloj y sacá su acceso directo de la carpeta de Inicio (`Win + R`, escribí `shell:startup`).

**El antivirus borra o bloquea el instalador.** A veces marcan por error a los programas hechos con AutoHotkey. Podés revisar el archivo en [VirusTotal](https://www.virustotal.com/) y, si confiás en él, permitirlo en tu antivirus.

¿Otra cosa? [Contanos acá](https://github.com/valedominguezl/illustrator-atajo-pincel/issues).

## De dónde sale el instalador

Lo compila [GitHub Actions](https://github.com/valedominguezl/illustrator-atajo-pincel/actions) a partir del código de este repositorio cada vez que se publica una versión, así cualquiera puede ver de qué código sale. En cada [versión](https://github.com/valedominguezl/illustrator-atajo-pincel/releases) está su SHA-256 para comprobar el archivo.

## Licencia

El código de este proyecto es [MIT](LICENSE). El programa instalado incluye el intérprete de [AutoHotkey](https://www.autohotkey.com/), que tiene su propia licencia, [GPL v2](licencias/AutoHotkey-GPLv2.txt), y su [código fuente](https://github.com/AutoHotkey/AutoHotkey) es público.
