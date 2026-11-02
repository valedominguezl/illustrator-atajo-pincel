# Illustrator: atajo de pincel

Cambiá el tamaño del pincel en Adobe Illustrator como en Photoshop, sin ir al panel.

Mantené **Shift + Alt** y mové el mouse, sin hacer clic: a la derecha agranda, a la izquierda achica. Mientras ajustás, un círculo rojo muestra el tamaño real y abajo aparece la medida en pt y mm.

Solo para Windows 10 u 11 de 64 bits.

## Instalar

1. **[Bajá el instalador](https://github.com/valedominguezl/illustrator-atajo-pincel/releases/latest/download/Instalar-Atajo-de-Pincel.exe)** y abrilo.
2. Si aparece «Windows protegió su PC», tocá **Más información** y después **Ejecutar de todos modos**. El aviso sale porque el instalador no tiene firma digital, un certificado pago. Más abajo explicamos de dónde sale.
3. Seguí el asistente. Te va a preguntar dos cosas:
   - **El tamaño de tu pincel.** Fijate en el panel Pinceles de Illustrator: el número del nombre es su tamaño (el pincel «5 pt. Round» es 5). Si usás el Lápiz, poné 1.
   - **Si el atajo arranca con Windows.** Dejalo tildado para no tener que abrirlo cada vez.

No hace falta instalar nada más ni tener permisos de administrador.

## Usar

1. Abrí un documento en Illustrator y elegí el Pincel, el Lápiz o la Pluma.
2. Mantené **Shift + Alt** y mové el mouse sin hacer clic.
3. Soltá las teclas y dibujá: lo próximo que dibujes sale con ese grosor.

Mientras el atajo está activo, vas a ver un ícono verde con una **H** junto al reloj de Windows (a veces queda escondido bajo la flechita **^**).

## Cambiar el tamaño del pincel

Hacé doble clic en el ícono de la **H** junto al reloj. Te pide el tamaño de tu pincel y el grosor máximo de la línea, y queda guardado.

Si cambiás de pincel en Illustrator, cambialo acá también: si no, el círculo rojo no va a coincidir con la línea.

## Activar o desactivar el arranque con Windows

Volvé a abrir el instalador y tildá o destildá la opción. Lo que ya elegiste se conserva.

Si no arranca con Windows, lo abrís cuando quieras buscando **Atajo de pincel para Illustrator** en el menú Inicio. Para cerrarlo, clic derecho en el ícono de la **H** y **Salir**.

## Desinstalar

Abrí **Configuración → Aplicaciones → Aplicaciones instaladas**, buscá **Atajo de pincel para Illustrator** y tocá **Desinstalar**. Se cierra el atajo y se borra todo lo que el instalador puso, incluido el arranque con Windows.

## Si algo no funciona

**Shift + Alt no hace nada.**
- Fijate que esté el ícono de la **H** junto al reloj. Si no está, abrí el atajo desde el menú Inicio.
- Tiene que haber un documento abierto en Illustrator y esa ventana tiene que estar al frente.
- Si abrís Illustrator como administrador, el atajo no puede hablar con él y no avisa. Abrí Illustrator de la forma normal, sin «Ejecutar como administrador». Si lo tenés configurado para abrirse siempre así, sacale esa opción en Propiedades → Compatibilidad de su acceso directo.

**El círculo rojo no coincide con la línea.** El tamaño cargado no es el de tu pincel. Cambialo como dice [más arriba](#cambiar-el-tamaño-del-pincel). El atajo no puede averiguar solo qué pincel estás usando.

**El tamaño salta el doble o el círculo parpadea.** Probablemente hay dos copias reaccionando a la vez. Pasa si antes usabas el script suelto `pincel-illustrator.ahk`: cerralo desde su ícono junto al reloj y sacá su acceso directo de la carpeta de Inicio (`Win + R`, escribí `shell:startup`).

**El antivirus borra o bloquea el instalador.** A veces marcan por error a los programas hechos con AutoHotkey. Podés revisar el archivo en [VirusTotal](https://www.virustotal.com/) y, si confiás en él, permitirlo en tu antivirus.

¿Otra cosa? [Contanos acá](https://github.com/valedominguezl/illustrator-atajo-pincel/issues).

## De dónde sale el instalador

Lo compila [GitHub Actions](https://github.com/valedominguezl/illustrator-atajo-pincel/actions) a partir del código de este repositorio cada vez que se publica una versión, así cualquiera puede ver de qué código sale. En cada [versión](https://github.com/valedominguezl/illustrator-atajo-pincel/releases) está su SHA-256 para comprobar el archivo.

## Licencia

El código de este proyecto es [MIT](LICENSE). El programa instalado incluye el intérprete de [AutoHotkey](https://www.autohotkey.com/), que tiene su propia licencia, [GPL v2](licencias/AutoHotkey-GPLv2.txt), y su [código fuente](https://github.com/AutoHotkey/AutoHotkey) es público.
