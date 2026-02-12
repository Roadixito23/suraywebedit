import 'package:flutter/material.dart';
import '../../../core/constants/app_breakpoints.dart';

/// Widget que proporciona padding adaptativo según el dispositivo
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  
  /// Padding para móvil
  final EdgeInsets mobilePadding;
  
  /// Padding para tablet
  final EdgeInsets? tabletPadding;
  
  /// Padding para desktop
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.mobilePadding = const EdgeInsets.all(16),
    this.tabletPadding,
    this.desktopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        EdgeInsets padding;
        
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          padding = desktopPadding ?? tabletPadding ?? mobilePadding;
        } else if (constraints.maxWidth >= AppBreakpoints.mobile) {
          padding = tabletPadding ?? mobilePadding;
        } else {
          padding = mobilePadding;
        }

        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

/// Widget que centra y limita el ancho del contenido en pantallas grandes
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  
  /// Ancho máximo del contenido
  final double maxWidth;
  
  /// Padding alrededor del contenido
  final EdgeInsets padding;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Widget que muestra una cuadrícula adaptativa
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  
  /// Columnas para móvil
  final int mobileColumns;
  
  /// Columnas para tablet
  final int tabletColumns;
  
  /// Columnas para desktop
  final int desktopColumns;
  
  /// Espacio entre elementos
  final double spacing;
  
  /// Aspect ratio de cada elemento
  final double childAspectRatio;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.childAspectRatio = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= AppBreakpoints.mobile) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
