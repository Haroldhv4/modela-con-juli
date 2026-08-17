# Modela con Juli — Pipeline definitivo de personaje modular

## Decisión

El juego no debe cambiar un GLB completo por cada prenda. El personaje final usa **un solo cuerpo y un solo Skeleton3D** y las prendas son meshes independientes ligados al mismo esqueleto.

Objetivo de escena:

```text
Juli
├── Skeleton3D
├── Body
├── Face
├── Hair
│   ├── hair_1
│   ├── hair_2
│   └── ...
├── Tops
│   ├── top_1
│   ├── top_2
│   └── ...
├── Bottoms
│   ├── skirt_1
│   ├── skirt_2
│   └── ...
├── Shoes
│   ├── shoes_1
│   ├── shoes_2
│   └── ...
└── Accessories
    ├── glasses_1
    └── ...
```

## Regla principal

Cada prenda 3D debe:

1. estar modelada sobre el cuerpo base de Juli;
2. usar el mismo armature/esqueleto;
3. conservar la misma pose de reposo;
4. tener pesos de vértices para los huesos que la deforman;
5. exportarse como mesh separado, no fusionado con `Body`;
6. mantener nombres estables (`top_1`, `skirt_1`, `shoes_1`, etc.).

La miniatura PNG del armario solo representa la prenda en UI. No es la prenda 3D.

## Flujo de arte recomendado

```text
Juli base GLB
    ↓
Blender / herramienta de autoría
    ↓
crear o adaptar prenda sobre el cuerpo
    ↓
transferir/ajustar pesos al mismo armature
    ↓
exportar GLB con meshes separados
    ↓
Godot importa un Skeleton3D compartido
    ↓
ModularWardrobe activa/desactiva meshes
```

## Cambio de prenda en runtime

El cambio debe ser prácticamente instantáneo:

```gdscript
func equip(category: String, item_id: String):
    for mesh in category_meshes[category]:
        mesh.visible = mesh.name == item_id
```

No se carga otro personaje, no se reemplaza el Skeleton3D y no se vuelve a cargar la cara/cabello/cuerpo.

## Animación

El personaje y las prendas deben compartir el mismo Skeleton3D. Las animaciones Idle, Walk, Catwalk y Pose se reproducen sobre ese esqueleto; las prendas siguen automáticamente al cuerpo por sus pesos.

Para animaciones externas usaremos retargeting humanoide de Godot (`SkeletonProfileHumanoid`) cuando el rig sea compatible.

## Referencias técnicas seleccionadas

- Configura (Godot): framework de personalización basado en meshes modulares, blendshapes, deformación esquelética y UI generada desde los assets.
- Quaternius Universal Animation Library: biblioteca CC0 de animaciones humanoides compatible con Godot y retargeting.
- Godot SkeletonProfileHumanoid: estándar de retargeting humanoide.

## Estado actual

- Chiyo queda descartada como base final del guardarropa porque cada outfit es un personaje completo y resulta demasiado pesado para este proyecto.
- `anime_school_girl_rigged.glb` vuelve a ser la base ligera mientras auditamos si sus meshes/superficies permiten reutilizar alguna parte.
- `RunwayV3.gd` deja de forzar brazos/piernas con rotaciones manuales y usa animaciones del modelo si existen; de no existir, usa solo movimiento de raíz sin deformar el rig.

## Criterio para aceptar una prenda nueva

Antes de entrar al catálogo del juego, una prenda debe pasar:

- no atravesar el cuerpo de forma visible en pose normal;
- seguir brazos/piernas/torso correctamente;
- no duplicar el cuerpo completo;
- cambiar en menos de un frame una vez cargada la escena;
- funcionar en lobby y pasarela sin cambiar de personaje;
- mantener consumo razonable para Android.
