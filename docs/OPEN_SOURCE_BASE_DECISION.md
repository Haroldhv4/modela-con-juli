# Base open source para Modela con Juli

Fecha de evaluación: 2026-08-17.

## Decisión

Usar **Team-Figoose/Configura** como referencia/base arquitectónica para el sistema de personalización 3D, integrando solamente la parte necesaria para el runtime del juego.

No se incorpora el proyecto de ejemplo completo porque Modela con Juli ya tiene lobby, arte, modelos y presets de exportación propios. La integración actual añade un puente ligero inspirado en el patrón de mesh swap de Configura y mantiene preparada una ruta para prendas skinned modulares.

## Comparación

| Proyecto | Licencia | Godot 4 | Prendas 3D reales | Rendimiento / encaje | Windows + Android | Decisión |
|---|---|---:|---:|---|---:|---|
| Team-Figoose/Configura | MIT | Sí; proyecto actual y basado en APIs de Godot 4 | Sí: assets modulares, mesh swap, blendshapes, deformación y materiales | Mejor encaje. Permite mantener un solo mesh por slot y separar herramientas de editor del runtime | Sí, al ser GDScript/recursos Godot y no requerir una plataforma nativa específica | **Elegido** |
| smix8/Godot3DCharacterEditorWardrobe | MIT | No directamente; ejemplo hecho para Godot 3.2 y archivado | Sí: reemplazo de meshes por slots | Código pequeño y útil como referencia, pero exige portar APIs y mantener nosotros el fork | Posible después de portar, pero no es una base conveniente para el proyecto Godot 4.7 actual | Descartado como base principal |
| GDQuest godot-4-3D-Characters | Código Godot disponible como proyecto open source; revisar licencia de cada asset | Sí | No es un framework de armario | Excelente como fuente de personajes/controladores, pero no resuelve guardar/equipar prendas | Sí | Complementario, no base de vestuario |

## Por qué Configura

1. Su modelo de datos separa el estado del personaje de los nodos 3D.
2. Su runtime contempla carga/descarga dinámica de meshes y evita mantener todas las prendas activas al mismo tiempo.
3. Está pensado para hair/clothing/accessories y para aplicar también blendshapes, color y deformación.
4. Nos deja mantener la UI propia de Modela con Juli en vez de imponer la UI del proyecto de ejemplo.
5. La licencia MIT permite adaptar el sistema conservando el aviso de copyright/licencia.

## Integración realizada en esta rama

- `addons/ConfiguraBridge/configura_wardrobe_runtime.gd`: runtime ligero para cambiar looks 3D y punto de extensión para meshes modulares.
- `scripts/LobbyUI_v12.gd`: conecta la selección del armario con el runtime 3D.
- `scenes/Runway.tscn` + `scripts/Runway.gd`: vertical slice jugable lobby -> vestuario -> guardar -> pasarela -> puntuación -> repetir/volver.
- `third_party/Configura/LICENSE.txt`: licencia MIT de Configura.

## Estado de assets 3D

El repositorio todavía no contiene para Juli un set completo de prendas independientes skinned que compartan su `Skeleton3D`. Por eso el MVP usa temporalmente los GLB completos ya presentes en `assets/characters/chiyo/` como **variantes de look 3D**. Esto demuestra el cambio real de geometría y cierra el flujo jugable sin esperar al pipeline final de arte.

La siguiente evolución no requiere rehacer el lobby ni el guardado: se exportará cada prenda de Juli como escena `MeshInstance3D` skinned al mismo esqueleto y se conectará a `equip_modular_mesh()` por slot (`hair`, `tops`, `bottoms`, `shoes`, `accessories`).

## Rendimiento

No se asume un benchmark que los repositorios no publican. La decisión de rendimiento es arquitectónica:

- una sola variante/personaje activa a la vez en el MVP;
- carga bajo demanda;
- renderer `gl_compatibility` ya configurado en el proyecto;
- Android limitado a `arm64-v8a` en el preset actual;
- futura ropa modular evita duplicar cuerpo/esqueleto por cada look completo.

Los GLB completos de Chiyo son temporales y más pesados que el objetivo final. Para Android, la optimización prioritaria después del vertical slice es separar prendas, reutilizar skeleton/materiales y comprimir texturas.
