import 'package:flutter/material.dart';
import '../../../core/constants/app_breakpoints.dart';

/// Enum para identificar el tipo de dispositivo
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Widget que detecta el tipo de dispositivo y proporciona builders específicos
class ResponsiveLayout extends StatelessWidget {
  /// Builder para dispositivos móviles (< 600px)
  final Widget Function(BuildContext context, BoxConstraints constraints) mobileBuilder;
  
  /// Builder para tablets (600px - 900px)
  final Widget Function(BuildContext context, BoxConstraints constraints)? tabletBuilder;
  
  /// Builder para desktop (>= 900px)
  final Widget Function(BuildContext context, BoxConstraints constraints)? desktopBuilder;

  const ResponsiveLayout({
    Key? key,
    required this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  }) : super(key: key);

  /// Obtiene el tipo de dispositivo basado en el ancho
  static DeviceType getDeviceType(double width) {
    if (AppBreakpoints.isMobile(width)) {
      return DeviceType.mobile;
    } else if (AppBreakpoints.isTablet(width)) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Verifica si el dispositivo actual es móvil
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppBreakpoints.mobile;
  }

  /// Verifica si el dispositivo actual es tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
  }

  /// Verifica si el dispositivo actual es desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = getDeviceType(constraints.maxWidth);

        switch (deviceType) {
          case DeviceType.desktop:
            return desktopBuilder?.call(context, constraints) ??
                tabletBuilder?.call(context, constraints) ??
                mobileBuilder(context, constraints);
          case DeviceType.tablet:
            return tabletBuilder?.call(context, constraints) ??
                mobileBuilder(context, constraints);
          case DeviceType.mobile:
          default:
            return mobileBuilder(context, constraints);
        }
      },
    );
  }
}
