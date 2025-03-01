# Sistema de Tests para el Inventario en Godot Roguelike

Este sistema permite ejecutar pruebas automatizadas para el sistema de inventario del juego.

## Estructura de Tests

El sistema de tests está organizado en los siguientes archivos:

1. **Tests de componentes individuales**:
   - `TestInventoryModel.gd`: Pruebas para el modelo de datos del inventario
   - `TestInventoryManager.gd`: Pruebas para el gestor de inventarios
   - `TestItemFactory.gd`: Pruebas para la fábrica de items
   - `TestInventoryUI.gd`: Pruebas para la interfaz de usuario del inventario

2. **Tests de ciclo completo**:
   - `TestSavedDataCycle.gd`: Pruebas que verifican el ciclo completo de crear ítems, guardarlos y cargarlos

## Cómo ejecutar los tests

Hemos implementado un sistema de tests propio con un script ejecutable y un archivo batch para facilitar su uso:

### Usando el script batch
```bash
# Ejecutar todos los tests
run_tests.bat

# Ejecutar un test específico
run_tests.bat inventory_model
run_tests.bat saved_data_cycle
```

### Manualmente desde la línea de comandos
```bash
# Ejecutar todos los tests
godot --path "C:\Godot RL\Godot-Roguelike" --script TestRunner.gd

# Ejecutar un test específico
godot --path "C:\Godot RL\Godot-Roguelike" --script TestRunner.gd --test=inventory_model
```

## Tipos de Tests

### Tests de Componentes
Verifican que cada componente individual del sistema de inventario funcione correctamente:
- Creación, modificación y eliminación de ítems
- Gestión de slots y capacidad del inventario
- Serialización y deserialización
- Creación de diferentes tipos de ítems

### Tests de Ciclo Completo
Comprueban el flujo de trabajo completo del inventario:
- Creación de ítems desde cero
- Guardado en archivo JSON independiente (`saved_data2.json`)
- Carga de ítems desde el archivo
- Modificación de posiciones y actualización
- Integración entre el InventoryManager y SavedData

## Añadir Nuevos Tests

1. Crea un nuevo archivo en la carpeta `Tests/` que extienda de `Reference`
2. Implementa métodos que comiencen con `test_` para cada caso de prueba
3. Añade el nuevo test al diccionario en `TestRunner.gd`

## Notas para Desarrolladores

- Los tests deben devolver `true` cuando pasan y `false` cuando fallan
- Puedes usar los métodos `setup()` y `teardown()` para inicializar y limpiar recursos entre tests
- El sistema de tests imprime un informe detallado de resultados al terminar
