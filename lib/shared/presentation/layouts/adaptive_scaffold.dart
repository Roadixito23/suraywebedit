import 'package:flutter/material.dart';
import '../../../core/constants/app_breakpoints.dart';

/// Scaffold base que adapta su contenido según el dispositivo
class AdaptiveScaffold extends StatelessWidget {
  /// Título del AppBar
  final String? title;
  
  /// Widget del título personalizado
  final Widget? titleWidget;
  
  /// Acciones del AppBar
  final List<Widget>? actions;
  
  /// Widget inferior del AppBar (ej: TabBar)
  final PreferredSizeWidget? bottom;
  
  /// Color de fondo del AppBar
  final Color? appBarColor;
  
  /// Cuerpo del scaffold para móvil
  final Widget body;
  
  /// Drawer para navegación lateral (móvil)
  final Widget? drawer;
  
  /// NavigationRail para desktop (lateral)
  final NavigationRail? navigationRail;
  
  /// Floating action button
  final Widget? floatingActionButton;
  
  /// Ubicación del FAB
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  
  /// BottomNavigationBar para móvil
  final Widget? bottomNavigationBar;
  
  /// Decoración del body
  final BoxDecoration? bodyDecoration;

  const AdaptiveScaffold({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    this.appBarColor,
    required this.body,
    this.drawer,
    this.navigationRail,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bodyDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;

        // En desktop, mostramos NavigationRail si está disponible
        if (isDesktop && navigationRail != null) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: Container(
              decoration: bodyDecoration,
              child: Row(
                children: [
                  navigationRail!,
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
          );
        }

        // En móvil/tablet, usamos el scaffold tradicional
        return Scaffold(
          appBar: _buildAppBar(),
          body: Container(
            decoration: bodyDecoration,
            child: body,
          ),
          drawer: drawer,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (title == null && titleWidget == null) return null;
    
    return AppBar(
      title: titleWidget ?? Text(title ?? ''),
      centerTitle: true,
      backgroundColor: appBarColor,
      actions: actions,
      bottom: bottom,
    );
  }
}
