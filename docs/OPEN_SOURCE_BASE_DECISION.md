# Base open source para Modela con Juli

Fecha de evaluación: 2026-08-17.

## Decisión

Usar **Team-Figoose/Configura** como referencia/base arquitectónica para el sistema de personalización 3D, integrando solamente la parte necesaria para el runtime del juego.

No se incorpora el proyecto de ejemplo completo porque Modela con Juli ya tiene lobby, arte, modelos y presets de exportación propios. La integración mantiene separadas la UI, el estado del outfit y la representación 3D.

## Comparación

| Proyecto | Licencia | Godot 4 | Prendas 3D reales | Rendimiento / encaje | Windows + Android | Decisión |
|---|---|---:|---:|---|---:|---|
| Team-Figoose/Configura | MIT | Sí | Sí: assets modulares, mesh swap, blendshapes, deformación y materiales | Mejor encaje para un personaje persistente con un mesh por slot | Sí | **Elegido como referencia** |
| smix8/Godot3DCharacterEditorWardrobe | MIT | Requiere portar desde Godot 3.2 | Sí | Útil como referencia, pero archivado y exige mantenimiento propio | Posible tras portar | Descartado como base principal |
| GDQuest godot-4-3D-Characters | Revisar licencia por asset | Sí | No es un framework de armario | Útil para controladores/personajes, no resuelve vestuario | Sí | Complementario |

## Corrección arquitectónica después del primer playtest

El primer vertical slice usó GLB completos de Chiyo como variantes para demostrar carga de geometría. El playtest mostró que ese enfoque es incorrecto para un juego de vestir porque cambia identidad, cuerpo, escala y ropa a la vez.

Desde esta revisión se aplica una regla estricta:

**Juli nunca se reemplaza para equipar una prenda.**

El runtime mantiene una única instancia de `assets/characters/juli/anime_school_girl_rigged.glb`. Mientras llegan las prendas modulares reales, intenta aplicar variaciones visuales sobre materiales/mallas detectados del propio modelo. Si una zona no puede aislarse con seguridad, conserva a Juli y el estado de selección en vez de cargar otro personaje.

## Integración actual

- `addons/ConfiguraBridge/configura_wardrobe_runtime.gd`
  - detecta `Skeleton3D` y `AnimationPlayer`;
  - intenta usar una animación idle existente;
  - si no existe, aplica una pose relajada de respaldo y movimiento idle sutil;
  - clasifica superficies por nombre/posición para variaciones visuales seguras;
  - contiene `equip_modular_mesh()` para las prendas skinned definitivas.
- `scripts/LobbyUI_v12.gd`
  - mantiene una sola Juli durante todo el Lobby;
  - guarda las seis categorías del outfit;
  - guarda el modo de juego;
  - no usa Chiyo para simular prendas.
- `scripts/GameSession.gd`
  - persiste modo, último resultado, mejor puntuación e historial.
- `scenes/Runway.tscn` + `scripts/Runway.gd`
  - carga siempre a Juli;
  - reaplica el outfit guardado;
  - cuenta regresiva, entrada, pose, tres jueces, puntuación, récord, repetir y volver.
- `third_party/Configura/LICENSE.txt`
  - conserva el aviso MIT de Configura.

## Estado de assets 3D

El repositorio todavía no contiene para Juli un set completo de prendas independientes skinned que compartan exactamente su `Skeleton3D`, nombres de huesos y bind pose.

Por tanto, el sistema actual es funcional a nivel de flujo y mantiene la identidad correcta del personaje, pero el cambio de **geometría real e independiente** para cada top, falda, zapato, cabello o lentes depende de incorporar esos assets modulares.

La ruta definitiva ya está preparada: cada prenda se exportará como escena `MeshInstance3D` skinned al mismo esqueleto y se conectará a `equip_modular_mesh()` por slot (`hair`, `tops`, `bottoms`, `shoes`, `accessories`).

## Rendimiento

- una sola Juli activa por escena;
- no se duplican cuerpos/esqueletos para cambiar de ropa;
- materiales se duplican solo al aplicar un estilo sobre una superficie concreta;
- renderer `gl_compatibility` ya configurado;
- preset Android actual limitado a `arm64-v8a`;
- la futura ropa modular mantiene un solo mesh activo por slot.

Esta arquitectura es más adecuada para Windows y Android que cargar personajes completos como outfits.
