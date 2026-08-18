# Modela con Juli

Juego 3D de vestir y pasarela desarrollado en Godot 4.

## Estado de esta rama

La rama `agent/configura-functional-base` prioriza un vertical slice completo antes del pulido visual:

1. Abrir el lobby.
2. Elegir prendas/look.
3. Cambiar un look 3D real desde la categoría de ropa superior.
4. Guardar el outfit.
5. Pulsar **Empezar pasarela**.
6. Ejecutar la secuencia de pasarela y pose.
7. Obtener puntuación.
8. Repetir o volver al lobby.

## Base de vestuario

Se eligió `Team-Figoose/Configura` como referencia arquitectónica por su licencia MIT y su enfoque de personalización modular 3D. La decisión completa está en `docs/OPEN_SOURCE_BASE_DECISION.md` y el aviso de licencia en `third_party/Configura/LICENSE.txt`.

El runtime integrado es deliberadamente pequeño: reutiliza la UI actual de Modela con Juli y deja preparado el salto de variantes de personaje completas a prendas skinned modulares por slot.

## Assets temporales

Mientras Juli todavía no tenga cabello, tops, faldas, zapatos y accesorios exportados como meshes 3D independientes compatibles con el mismo skeleton, el vertical slice usa los looks 3D de Chiyo que ya están en el repositorio para probar el flujo completo.

Estos assets son placeholders de desarrollo. Antes de una distribución comercial hay que confirmar la licencia/procedencia de cada modelo y textura del proyecto.

## Exportación

El proyecto conserva los presets existentes para:

- Windows Desktop x86_64
- Android arm64-v8a

El renderer continúa en `gl_compatibility`, adecuado para mantener una ruta conservadora hacia PC y Android.

## Próximo objetivo

Convertir el vestuario visual actual a prendas 3D modulares de Juli, conectando cada asset a los slots del runtime sin volver a construir la UI, guardado o pasarela.
