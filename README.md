# Modela con Juli

Juego 3D de vestir y pasarela desarrollado en Godot 4.

## Flujo funcional actual

La versión activa prioriza tener un juego completo y estable antes del pulido visual:

1. Abrir el lobby con una única instancia de Juli.
2. Elegir cabello, ropa superior, inferior, zapatos, accesorios y maquillaje.
3. Aplicar el estilo sobre la misma Juli; el juego ya no sustituye el personaje por modelos completos de Chiyo.
4. Guardar el outfit y el modo de juego.
5. Pulsar **Empezar pasarela**.
6. Cuenta regresiva, entrada, pose y evaluación del jurado.
7. Obtener puntuación, guardar récord y repetir o volver al lobby.

## Vestuario 3D

Se usa `Team-Figoose/Configura` como referencia arquitectónica por su licencia MIT y su enfoque de personalización modular 3D. El aviso de licencia está en `third_party/Configura/LICENSE.txt`.

El runtime actual mantiene a Juli persistente, detecta `Skeleton3D`, intenta reproducir una animación idle si existe y, si el GLB no la trae, aplica una pose relajada de respaldo. También clasifica mallas/materiales por nombre y posición para aplicar variaciones visuales sin cambiar de personaje.

La ruta definitiva ya está preparada con slots de `MeshInstance3D`: cuando tengamos prendas skinned independientes que compartan exactamente el mismo skeleton/bind pose de Juli, cada slot podrá reemplazar solo su prenda real.

## Importante sobre los assets actuales

El repositorio todavía no contiene un conjunto completo de cabello, tops, faldas/pantalones, zapatos y lentes exportados como mallas 3D independientes para Juli. Por eso algunas opciones solo pueden variar materiales/colores del modelo actual hasta que esas prendas modulares estén disponibles.

No se usan los modelos completos de Chiyo para simular cambios de ropa en el flujo nuevo.

## Pasarela

La pasarela carga siempre `assets/characters/juli/anime_school_girl_rigged.glb`, reaplica el outfit guardado, ejecuta una secuencia de entrada/pose y muestra tres puntuaciones de jurado, puntuación final y mejor récord persistente.

## Exportación

El proyecto conserva los presets existentes para:

- Windows Desktop x86_64
- Android arm64-v8a

El renderer continúa en `gl_compatibility` para mantener una ruta conservadora hacia PC y Android.

## Próximo objetivo técnico

La prioridad siguiente es incorporar las primeras prendas 3D modulares reales de Juli sobre un único `Skeleton3D`. Después de eso se continúa con animaciones de pasarela más completas, tienda/progresión y finalmente pulido visual del lobby.
