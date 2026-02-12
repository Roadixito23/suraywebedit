/// Breakpoints para diseño responsive
class AppBreakpoints {
  /// Ancho máximo para considerar móvil
  static const double mobile = 600;
  
  /// Ancho máximo para considerar tablet
  static const double tablet = 900;
  
  /// Ancho mínimo para considerar desktop
  static const double desktop = 1200;
  
  /// Verifica si el ancho corresponde a móvil
  static bool isMobile(double width) => width < mobile;
  
  /// Verifica si el ancho corresponde a tablet
  static bool isTablet(double width) => width >= mobile && width < tablet;
  
  /// Verifica si el ancho corresponde a desktop
  static bool isDesktop(double width) => width >= tablet;
}
