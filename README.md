# Illustrator: atajo de pincel

Cambiá el tamaño del pincel en Adobe Illustrator como en Photoshop, sin ir al panel.

Apretá **Shift**, después **Alt**, y mové el mouse sin hacer clic: a la derecha agranda, a la izquierda achica. El círculo de vista previa de Illustrator se actualiza mientras ajustás, y al lado aparece el Stroke en pt y mm.

Solo para Windows 10 u 11 de 64 bits.

## Instalar

1. **[Bajá el instalador](https://github.com/valedominguezl/illustrator-atajo-pincel/releases/latest/download/Instalar-Atajo-de-Pincel.exe)** y abrilo.
2. Si aparece «Windows protegió su PC», tocá **Más información** y después **Ejecutar de todos modos**. El aviso sale porque el instalador no tiene firma digital, un certificado pago. Más abajo explicamos de dónde sale.
3. Seguí el asistente. Te pregunta **si el atajo arranca con Windows**: dejalo tildado para no tener que abrirlo cada vez.
4. Listo: queda con las velocidades de fábrica. Si querés probarlas, en la última pantalla tocá **Cambiar la sensibilidad (opcional)**. Con esa ventana al frente, apretá Shift, después Alt, y mové el mouse. Ajustá a tu gusto y tocá **Guardar**.

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
| Shift + Alt + **Bloq Mayús** (con o sin Ctrl) | De a 0,5 |

Los pasos van en la unidad que Illustrator usa para el Stroke, con el pincel y con cualquier otra herramienta. En mm van de a 1 mm y de a 0,5 mm; en pt, de a 1 pt y de a 0,5 pt.

## Cambiar entre puntos y milímetros

Mientras mantenés Shift + Alt, apretá **A**: el Stroke pasa de pt a mm y viceversa. El grosor de la línea no cambia, solo la unidad en que se mide. La opción queda guardada en Illustrator (Edit → Preferences → Units → Stroke) hasta que la vuelvas a cambiar.

## Cambiar la sensibilidad y las teclas

Hacé doble clic en el ícono de la **H** junto al reloj de Windows (a veces está bajo la flechita **^**). Ahí podés probar el gesto, cambiar la velocidad de cada modo y elegir qué teclas se suman a Shift + Alt. **Valores de fábrica** vuelve todo a como estaba.

Shift + Alt queda fijo, porque otras teclas cambian de herramienta en Illustrator y esconden el círculo.

## Tope

El atajo no sube el Stroke de 400 pt, aunque trabajes en otra unidad. El grosor final de la línea puede ser mayor, porque el pincel lo multiplica.

## Activar o desactivar el arranque con Windows

Volvé a abrir el instalador y tildá o destildá la opción.

Si no arranca con Windows, lo abrís cuando quieras buscando **Atajo de pincel para Illustrator** en el menú Inicio. Para cerrarlo, clic derecho en el ícono de la **H** y **Salir**.

## Si lo cerraste sin querer

No se rompe nada: solo deja de funcionar Shift + Alt. Buscá **Atajo de pincel para Illustrator** en el menú Inicio y abrilo: va a aparecer la ventana de ajustes, y el atajo ya queda funcionando aunque la cierres. Tus ajustes se conservan.

## Desinstalar

Abrí **Configuración → Aplicaciones → Aplicaciones instaladas**, buscá **Atajo de pincel para Illustrator** y tocá **Desinstalar**. Se cierra el atajo y se borra todo lo que el instalador puso, incluido el arranque con Windows.

## Si algo no funciona

**Shift + Alt no hace nada.**
- Fijate que esté el ícono de la **H** junto al reloj. Si no está, abrí el atajo desde el menú Inicio.
- Tiene que haber un documento abierto en Illustrator y esa ventana tiene que estar al frente.
- Si abrís Illustrator como administrador, el atajo no puede hablar con él y no avisa. Abrí Illustrator de la forma normal, sin «Ejecutar como administrador». Si lo tenés configurado para abrirse siempre así, sacale esa opción en Propiedades → Compatibilidad de su acceso directo.

**En un documento nuevo, el pincel no toma el tamaño.** Es una limitación de Illustrator: hasta que dibujás el primer trazo con el pincel, ignora el tamaño que le pone el atajo. Dibujá una línea cualquiera y bórrala con la tecla Suprimir: desde ahí funciona en todo el documento, aunque cambies de herramienta. Si en cambio la deshacés con Ctrl + Z, vuelve a pasar. Mientras el documento está vacío, el atajo te lo recuerda junto al cursor.

**No veo el círculo mientras ajusto.** Apretá Shift antes que Alt. El círculo lo dibuja Illustrator: si tu versión o tu herramienta no lo muestran, el Stroke igual cambia y podés guiarte por la medida que aparece junto al cursor.

**El número junto al cursor no coincide con el grosor de la línea.** Es normal: muestra el Stroke, y el pincel lo multiplica. Con un pincel de 3 pt y Stroke de 10 pt, la línea sale de 30 pt. El círculo sí muestra el grosor final.

**El tamaño salta el doble o el círculo parpadea.** Probablemente hay dos copias reaccionando a la vez. Pasa si antes usabas el script suelto `pincel-illustrator.ahk`: cerralo desde su ícono junto al reloj y sacá su acceso directo de la carpeta de Inicio (`Win + R`, escribí `shell:startup`).

**El mouse quedó quieto y no se suelta.** Soltá Shift y Alt, o apretá **Esc**: el atajo suelta el mouse. Igual lo suelta solo a los 20 segundos. Si aun así sigue quieto, apretá **Ctrl + Alt + Supr** y después **Esc**: Windows lo libera. Contanos cómo pasó [acá](https://github.com/valedominguezl/illustrator-atajo-pincel/issues).

**El antivirus borra o bloquea el instalador.** A veces marcan por error a los programas hechos con AutoHotkey. Podés revisar el archivo en [VirusTotal](https://www.virustotal.com/) y, si confiás en él, permitirlo en tu antivirus.

¿Otra cosa? [Contanos acá](https://github.com/valedominguezl/illustrator-atajo-pincel/issues).

## Si sabés un poco de programar

Podés cambiar el atajo en tu propia PC. Es un solo archivo de [AutoHotkey v2](https://www.autohotkey.com/): [`pincel-illustrator.ahk`](pincel-illustrator.ahk).

1. Instalá AutoHotkey v2: `winget install AutoHotkey.AutoHotkey`.
2. Bajá este repositorio con **Code → Download ZIP** o `git clone`.
3. **Cerrá el atajo instalado**: clic derecho en la **H** y **Salir**. Si quedan dos copias abiertas, las dos reaccionan a Shift + Alt.
4. Abrí `pincel-illustrator.ahk` en un editor y cambiá lo que quieras:

   | Qué querés cambiar | Dónde, al principio del archivo |
   |---|---|
   | Velocidad del modo libre | `BASE_LIBRE`: más alto, más lento |
   | Velocidad de los pasos de 1 y 0,5 | `BASE_FIJO`: más alto, más lento |
   | Cuánto cambia cada paso libre | `FACTOR`: `1.03` es un 3 % |
   | Tope del Stroke | `MAXIMO_STROKE`, en pt |
   | Teclas y sensibilidad de fábrica | `FABRICA` |
   | Teclas que se pueden elegir en la ventana | `TECLAS` |
   | El gesto Shift + Alt | Los atajos `+LAlt`, `+RAlt`, `!LShift` y `!RShift`, y el `while` de `Ajustar()` |

   Si cambiás Shift + Alt, evitá Ctrl y Alt sueltos: Illustrator cambia de herramienta con ellos y esconde el círculo.

5. Hacé doble clic en el archivo para probarlo. Si lo cambiás de nuevo, volvé a abrirlo: reemplaza a la copia anterior.
6. Si los valores guardados en la ventana te pisan lo que cambiaste, borrá `pincel.ini`, que queda junto al archivo.

Para que arranque con Windows, poné un acceso directo al archivo en la carpeta de Inicio (`Win + R`, escribí `shell:startup`).

Para armar tu propio instalador, corré `instalador\compilar.ps1` en PowerShell. Instala lo que falte y lo deja en `dist\`. Si hacés un fork, GitHub Actions lo compila con cada push y crea una versión con cada tag `vX.Y.Z`.

## De dónde sale el instalador

Lo compila [GitHub Actions](https://github.com/valedominguezl/illustrator-atajo-pincel/actions) a partir del código de este repositorio cada vez que se publica una versión, así cualquiera puede ver de qué código sale. En cada [versión](https://github.com/valedominguezl/illustrator-atajo-pincel/releases) está su SHA-256 para comprobar el archivo.

## Licencia

El código de este proyecto es [MIT](LICENSE). El programa instalado incluye el intérprete de [AutoHotkey](https://www.autohotkey.com/), que tiene su propia licencia, [GPL v2](licencias/AutoHotkey-GPLv2.txt), y su [código fuente](https://github.com/AutoHotkey/AutoHotkey) es público.
