# Cambios Detallados por Archivo

## 📄 `lib/theme/app_colors.dart` ⭐ NUEVO

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Colores principales Cobre/Bronce
  static const Color copper = Color(0xFFB87333);
  static const Color bronzeLight = Color(0xFFCD7F32);
  static const Color bronzeDark = Color(0xFF8B4513);
  
  // Colores complementarios
  static const Color orangeAccent = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFF8C42);
  static const Color blueDark = Color(0xFF004E89);
  static const Color blueLight = Color(0xFF1A5490);
  
  // Colores neutrales
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color darkGrey = Color(0xFF333333);
  static const Color grey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFE8E8E8);
  static const Color veryLightGrey = Color(0xFFF5F5F5);
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFf44336);
  static const Color warning = Color(0xFFFFC107);
}
```

---

## 📄 `lib/theme/app_theme.dart` ⭐ NUEVO

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.copper,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'Roboto',
      
      // AppBar: Cobre sólido
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.copper,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      
      // TabBar: Cobre con indicador naranja
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.orangeLight,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withOpacity(0.7),
      ),
      
      // Botones: Cobre
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.copper,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // TextButton: Cobre
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.copper,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      
      // Tarjetas: Redondeadas
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Inputs: Cobre cuando están enfocados
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.veryLightGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.copper, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.grey),
        prefixIconColor: AppColors.copper,
      ),
      
      // Diálogos: Redondeados
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Indicadores: Cobre
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.copper,
      ),
    );
  }
}
```

---

## 📄 `lib/main.dart` ✏️ MODIFICADO

### ❌ Antes
```dart
theme: ThemeData(
  primarySwatch: Colors.blue,
  fontFamily: 'Roboto',
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade800,
    elevation: 2,
    centerTitle: true,
  ),
  // ... más configuración dispersa
),
```

### ✅ Después
```dart
import 'theme/app_theme.dart';

// ...
theme: AppTheme.lightTheme,
```

---

## 📄 `lib/splash_screen.dart` ✏️ MODIFICADO

### ❌ Antes
```dart
colors: [Colors.blue.shade700, Colors.blue.shade300],

child: const Icon(
  Icons.directions_bus_rounded,
  size: 80,
  color: Colors.blue,
),

valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
```

### ✅ Después
```dart
import 'theme/app_colors.dart';

colors: [AppColors.copper, AppColors.bronzeLight],

child: const Icon(
  Icons.directions_bus_rounded,
  size: 80,
  color: AppColors.copper,
),

valueColor: AlwaysStoppedAnimation<Color>(AppColors.orangeLight),
```

---

## 📄 `lib/home.dart` ✏️ MODIFICADO (Cambios significativos)

### ❌ Antes
```dart
final Color _aysenColor = Colors.blue.shade700;
final Color _coyhaiqueCplor = Colors.green.shade700;
// ... colores diferentes por comunidad
backgroundColor: Colors.blue.shade800,
// ... SnackBar con Colors.red, Colors.green
```

### ✅ Después
```dart
import 'theme/app_colors.dart';

static const Color _primaryColor = AppColors.copper;
// ... color único unificado

backgroundColor: _primaryColor,
// ... todos los elementos usan _primaryColor

backgroundColor: AppColors.success,  // Verde
backgroundColor: AppColors.error,    // Rojo

// Gradiente actualizado
gradient: LinearGradient(
  colors: [AppColors.bronzeLight, Color(0xFFF9F5F0)],
)

// TabBar con indicador naranja
indicatorColor: AppColors.orangeLight,

// Botones con color principal
backgroundColor: _primaryColor,

// Iconos con color principal
color: _primaryColor,

// Errores con color de error
color: AppColors.error,

// Indicadores de progreso con color principal
valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
```

### Cambios Específicos en home.dart

**1. Variables de Color**
- ❌ `final Color _aysenColor = Colors.blue.shade700;`
- ❌ `final Color _coyhaiqueCplor = Colors.green.shade700;`
- ✅ `static const Color _primaryColor = AppColors.copper;`

**2. AppBar**
- ❌ `backgroundColor: Colors.blue.shade800,`
- ✅ `backgroundColor: _primaryColor,`

**3. TabBar**
- ❌ `indicatorColor: Colors.white,`
- ✅ `indicatorColor: AppColors.orangeLight,`

**4. Fondos**
- ❌ `colors: [Colors.blue.shade50, Colors.white]`
- ✅ `colors: [AppColors.bronzeLight, Color(0xFFF9F5F0)]`

**5. Diálogos y Botones**
- ❌ `style: TextStyle(color: comuna == 'aysen' ? _aysenColor : _coyhaiqueCplor)`
- ✅ `style: TextStyle(color: _primaryColor)`

**6. Snackbars**
- ❌ `backgroundColor: Colors.green,`
- ✅ `backgroundColor: AppColors.success,`

- ❌ `backgroundColor: Colors.red,`
- ✅ `backgroundColor: AppColors.error,`

**7. Iconos**
- ❌ `color: headerColor,`
- ✅ `color: _primaryColor,` (o `AppColors.error` para delete)

**8. Tarjetas**
- Todas usan color de fondo unificado basado en `_primaryColor`

---

## 🎯 Resumen de Cambios por Tipo

### Colores Reemplazados

| Anterior | Actual | Elemento |
|----------|--------|----------|
| `Colors.blue.shade700/.800` | `AppColors.copper` | AppBar, headers |
| `Colors.green.shade700` | `AppColors.copper` | Headers secundarios |
| `Colors.blue.shade50` | `AppColors.bronzeLight` | Fondos |
| `Colors.white` | `AppColors.white` | Backgrounds |
| `Colors.red` | `AppColors.error` | Errores, delete |
| `Colors.green` | `AppColors.success` | Success messages |
| `Colors.white` (indicador) | `AppColors.orangeLight` | TabBar indicator |

---

## ✅ Validación

- ✅ No hay errores de compilación
- ✅ Todos los imports son correctos
- ✅ Colores aplicados consistentemente
- ✅ Tema centralizado y reutilizable
- ✅ Listo para expandir con más pantallas
