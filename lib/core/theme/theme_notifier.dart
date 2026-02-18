import 'package:flutter/material.dart';

/// Notificador global del modo de tema (claro/oscuro).
/// Cualquier widget puede leer o cambiar el modo importando esta variable.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
