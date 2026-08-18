# Vestuario 3D de Juli

Esta carpeta contiene las prendas reales que se equipan sobre una unica instancia de Juli.

Convencion de rutas:

- `hair/hair_1.glb`, `hair_2.glb`, ...
- `tops/top_1.glb`, `top_2.glb`, ...
- `bottoms/skirt_1.glb`, `skirt_2.glb`, ...
- `shoes/shoes_1.glb`, `shoes_2.glb`, ...
- `accessories/glasses_1.glb`, `glasses_2.glb`, ...

Tambien se aceptan `.tscn` y `.gltf` con el mismo nombre de item.

## Requisito obligatorio

Una prenda skinned debe haber sido creada/ajustada para el cuerpo de Juli y compartir su rig/bind pose. El runtime apunta los `MeshInstance3D` de la prenda al `Skeleton3D` persistente de Juli; no sustituye el personaje completo.

No usar los GLB de Chiyo como prendas de Juli: su skeleton usa nombres y estructura diferentes y no es compatible con el rig actual de Juli.

## Flujo

1. Modelar o ajustar la prenda sobre la malla de Juli en Blender/VRoid u otra herramienta 3D.
2. Transferir pesos desde el cuerpo/base de Juli y conservar el rig compatible.
3. Exportar únicamente la prenda como GLB, incluyendo `Skin`/pesos necesarios.
4. Guardarla en la carpeta/ID correspondiente.
5. El Lobby la detecta automáticamente al pulsar su tarjeta y reemplaza solo el slot anterior.
