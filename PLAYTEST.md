# Modela con Juli — playtest de la rama gameplay

Rama: `feature/complete-gameplay-v1`

## Qué incluye

- Lobby visual existente conservado.
- Chiyo reemplaza al personaje provisional en tiempo de ejecución.
- Cambio visible entre cuatro variantes del pack Chiyo: Base, Casual, Escolar y Yukata.
- Las tarjetas de ropa superior, pantalones y calzado disparan cambios de outfit 3D.
- El color del cabello cambia usando el mesh `Hair` del personaje.
- Giro con mouse + rueda en PC.
- Giro y zoom por arrastre táctil en Android.
- Idle suave del cuerpo y, si los huesos se reconocen, movimiento ligero de cabeza/torso/brazos.
- Nueva escena `Runway.tscn`.
- Botón **EMPEZAR PASARELA** abre la pasarela.
- Secuencia automática: entrada → caminata → pose → regreso → puntuación.
- Movimiento esquelético de piernas/brazos de mejor esfuerzo cuando los nombres de huesos coinciden.
- Puntuación local, estrellas, Repetir y Volver al lobby.
- Modos Clásico, Duelo de Estilo y Desafío Diario guardados entre escenas.
- Duelo muestra rival local y resultado; Desafío Diario usa una meta de puntuación.
- Eventos, Clasificación y Equipo abren paneles locales funcionales.
- Clasificación guarda mejor puntuación, última puntuación, número de pasarelas e historial reciente.
- Fondo boutique reutilizado detrás de la pasarela para mantener el proyecto ligero en Android.

## Cómo probar

1. Cambia a la rama:
   ```bash
   git checkout feature/complete-gameplay-v1
   git pull
   ```
2. Abre `project.godot` con Godot 4.7.1.
3. Espera a que termine la reimportación de los GLB.
4. Ejecuta con F5.
5. En el lobby:
   - arrastra a Juli para girarla;
   - usa rueda del mouse para zoom;
   - selecciona distintas tarjetas en Ropa superior / Pantalones / Calzado;
   - comprueba que el modelo 3D cambia de conjunto;
   - selecciona Cabello para comprobar los tonos;
   - prueba Clásico / Duelo / Desafío Diario;
   - abre Eventos, Clasificación y Equipo.
6. Pulsa **EMPEZAR PASARELA** y deja completar la secuencia.
7. Comprueba puntuación y estrellas. En Duelo o Desafío Diario aparecerá además el resultado propio del modo.
8. Prueba `REPETIR` y `VOLVER AL LOBBY`.
9. Vuelve a Clasificación y confirma que se guardó el resultado.

## Android

La rama conserva `gl_compatibility` y ETC2/ASTC del proyecto. Después de comprobar F5 en PC, vuelve a exportar el APK desde el preset Android y prueba giro táctil, zoom vertical y botones.

## Limitación actual del asset Chiyo

Los GLB exportados contienen `Face`, `Body`, `Hair` y `Skeleton3D`, pero los atuendos vienen como modelos completos. Por eso esta primera implementación intercambia el outfit completo para las categorías de ropa. El sistema ya está desacoplado mediante `OutfitRuntime.gd`, de modo que cuando tengamos prendas 3D separadas (Top / Bottom / Shoes) podremos sustituir esa capa sin rehacer la interfaz, guardado ni pasarela.
