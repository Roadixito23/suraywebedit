# Sistema de Colores y Diseño Unificado - Suray WebEdit

## Cambios Implementados

### 1. **Nueva Estructura de Colores**
Se creó un sistema centralizado de colores en `lib/theme/app_colors.dart` con los siguientes colores:

#### Colores Principales (Cobre/Bronce)
- **Cobre**: `#B87333` - Color principal
- **Bronce Claro**: `#CD7F32` - Colores secundarios y fondos
- **Bronce Oscuro**: `#8B4513` - Acentos metálicos

#### Colores Complementarios
- **Naranja Oscuro**: `#FF6B35` - Acentos e indicadores
- **Naranja Claro**: `#FF8C42` - Indicadores de pestañas
- **Azul Oscuro**: `#004E89` - Reservado para futura expansión
- **Azul Claro**: `#1A5490` - Reservado para futura expansión

#### Colores de Estado
- **Success (Verde)**: `#4CAF50` - Operaciones exitosas
- **Error (Rojo)**: `#f44336` - Errores y eliminaciones
- **Warning (Amarillo)**: `#FFC107` - Advertencias

### 2. **Tema Centralizado**
Se creó `lib/theme/app_theme.dart` con:
- Configuración unificada del AppBar (Cobre)
- Tema de botones elevados consistente
- Decoración de inputs de texto uniforme
- Tema de diálogos redondeados
- Tema de indicadores de progreso

### 3. **Cambios en Archivos**

#### `main.dart`
- Importa y usa `AppTheme.lightTheme`
- Elimina temas locales dispersos
- Centraliza toda la configuración visual

#### `splash_screen.dart`
- Gradiente actualizado: Cobre → Bronce Claro
- Icono del bus en color Cobre
- Indicador de carga en Naranja Claro

#### `home.dart` (Cambios principales)
- Elimina variables de color específicas por comunidad
- Usa colores centralizados (`_primaryColor`, `_accentColor`)
- AppBar con color Cobre
- Indicador de TabBar en Naranja Claro
- Gradiente de fondo: Bronce Claro → Blanco roto
- Tarjetas de encabezado con Cobre
- Iconos consistentes en Cobre
- Botones de edición/eliminación con colores apropiados
- Snackbars con colores correctos (Success/Error)

### 4. **Beneficios**
✅ **Consistencia Visual**: Toda la app usa los mismos colores
✅ **Mantenimiento Simplificado**: Cambiar colores es fácil en un solo lugar
✅ **Profesionalismo**: Paleta cobre/bronce elegante y coherente
✅ **Accesibilidad**: Colores de estado claros (éxito/error)
✅ **Escalabilidad**: Fácil agregar nuevas pantallas con tema uniforme

### 5. **Estructura de Directorios**
```
lib/
├── theme/
│   ├── app_colors.dart (Nuevos - Constantes de colores)
│   └── app_theme.dart (Nuevos - Definición del tema)
├── main.dart (Modificado)
├── splash_screen.dart (Modificado)
├── home.dart (Modificado)
└── ... (otros archivos)
```

## Próximas Pantallas
Cualquier nueva pantalla en la app debería importar y usar:
```dart
import 'theme/app_colors.dart';

// Usar AppColors.copper, AppColors.orangeLight, etc.
```

## Notas de Implementación
- Todos los SnackBars ahora usan `AppColors.success` y `AppColors.error`
- Los diálogos mantienen coherencia visual con el tema principal
- Las animaciones de carga usan los colores principales
- Los tabs tienen indicador en Naranja Claro para mejor visibilidad
