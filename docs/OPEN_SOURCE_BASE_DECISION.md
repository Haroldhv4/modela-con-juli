# Base open source para Modela con Juli

## Decisión

Usar **Team-Figoose/Configura** como referencia arquitectónica para el sistema de personalización 3D, sin importar su demo completa dentro del juego.

La regla de runtime es: **una sola Juli persistente**. Equipar una prenda nunca debe sustituir a Juli por otro personaje.

## Estado técnico comprobado

El inspector automático ejecutado con Godot 4.7.1 confirmó para `anime_school_girl_rigged.glb`:

- 4 `MeshInstance3D` con nombres/materiales genéricos.
- `Skeleton3D` con 121 huesos.
- No contiene `AnimationPlayer`/animaciones importadas.

También se compararon los GLB de Chiyo con Juli. Sus rigs usan convenciones completamente diferentes (`J_Bip_*` frente a `Bip001 *`) y no comparten nombres de hueso con el rig actual de Juli. Por ello **los modelos de Chiyo no se usan como prendas de Juli**.

## Vestuario real

El runtime seguro está en `addons/ConfiguraBridge/wardrobe_runtime_v2.gd`.

Busca prendas por slot usando estas rutas:

- `assets/wardrobe3d/hair/hair_*.glb`
- `assets/wardrobe3d/tops/top_*.glb`
- `assets/wardrobe3d/bottoms/skirt_*.glb`
- `assets/wardrobe3d/shoes/shoes_*.glb`
- `assets/wardrobe3d/accessories/glasses_*.glb`

Cada prenda debe estar ajustada al cuerpo de Juli y compartir su rig/bind pose. Cuando existe, el Lobby reemplaza únicamente la prenda activa de ese slot. Si no existe todavía, Juli permanece intacta.

## Seguridad del esqueleto

Se eliminó la pose heurística que modificaba brazos/manos. El runtime V2 no altera huesos manualmente. Solo reproducirá una animación real si el modelo la contiene; actualmente Juli no contiene animaciones.

## Siguiente hito

Crear/exportar el primer conjunto de prendas 3D skinned compatibles con Juli (top, inferior, zapatos, cabello/accesorio) y colocarlas en `assets/wardrobe3d`. A partir de ese momento las tarjetas existentes del armario las detectan sin reescribir la UI.
