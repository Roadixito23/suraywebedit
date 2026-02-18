import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/constants/app_breakpoints.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../schedule/presentation/pages/schedule_page.dart';
import '../../../schedule/presentation/widgets/user_dialogs.dart';
import '../layouts/mobile_dashboard_layout.dart';
import '../layouts/desktop_dashboard_layout.dart';
import '../widgets/dashboard_cards.dart';
import '../../data/services/audit_service.dart';
import '../../data/services/statistics_service.dart';
import 'audit_page.dart';

/// Página principal del Dashboard con layouts responsivos
class DashboardPage extends StatefulWidget {
  final AuthService authService;

  const DashboardPage({super.key, required this.authService});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final FirebaseFirestore _firestore;
  final AuditService _auditService = AuditService();
  final StatisticsService _statisticsService = StatisticsService();

  // Datos del dashboard
  int _visitsCount = 0;
  int _dailyDepartures = 42;
  bool _isDbConnected = true;
  String _lastDbCheck = 'Hace 2 min';
  int _totalRoutes = 3;
  int _activeUsers = 5;

  // Logs de auditoría reales
  List<AuditLogEntry> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _checkDbConnection();
    _loadDashboardData();
    _loadAuditLogs();
    _loadVisitasHoy();
  }

  /// Cargar logs de auditoría desde Firebase
  Future<void> _loadAuditLogs() async {
    try {
      final logs = await _auditService.getAuditLogs(limit: 3);
      if (mounted) {
        setState(() {
          _auditLogs = logs.map((log) => AuditLogEntry(
            action: log.actionDescription,
            user: log.username,
            time: log.formattedTime,
            icon: log.icon,
            color: log.color,
          )).toList();
        });
      }
    } catch (e) {
      // Mantener lista vacía si hay error
      debugPrint('Error cargando audit logs: $e');
    }
  }

  /// Cargar total de visitas desde Firestore (estadisticas/visitas)
  Future<void> _loadVisitasHoy() async {
    final count = await _statisticsService.getVisitas();
    if (mounted) {
      setState(() {
        _visitsCount = count;
      });
    }
  }

  /// Verificar conexión a Firebase
  Future<void> _checkDbConnection() async {
    try {
      // Usamos estadisticas/visitas que tiene lectura permitida
      await _firestore.collection('estadisticas').doc('visitas').get();
      if (mounted) {
        setState(() {
          _isDbConnected = true;
          _lastDbCheck = 'Ahora';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDbConnected = false;
          _lastDbCheck = 'Error de conexión';
        });
      }
    }
  }

  /// Cargar datos del dashboard desde Firestore
  Future<void> _loadDashboardData() async {
    try {
      // Determinar subcollección según el día actual
      final dayOfWeek = DateTime.now().weekday;
      final String dayType;
      if (dayOfWeek >= 1 && dayOfWeek <= 5) {
        dayType = 'weekday';           // Lunes a Viernes
      } else if (dayOfWeek == 6) {
        dayType = 'saturday';          // Sábado
      } else {
        dayType = 'domingosFeriados';  // Domingo
      }

      int departures = 0;
      for (final comuna in ['aysen', 'coyhaique', 'limache']) {
        final docs = await _firestore
            .collection('horarios')
            .doc(comuna)
            .collection(dayType)
            .get();
        departures += docs.docs.length;
      }

      if (mounted) {
        setState(() {
          _dailyDepartures = departures;
        });
      }
    } catch (e) {
      // Mantener valor anterior si hay error
    }
  }

  /// Navegar a horarios
  void _navigateToSchedules() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchedulePage(authService: widget.authService),
      ),
    );
  }

  /// Navegar a auditoría
  void _navigateToAudit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AuditPage(),
      ),
    );
  }

  /// Mostrar diálogo de gestión de usuarios
  void _showUsersManagement() {
    UserDialogs.showAllUsersDialog(context, widget.authService);
  }

  /// Mostrar diálogo de cambio de contraseña
  void _showChangePassword() {
    UserDialogs.showChangePasswordDialog(context, widget.authService);
  }

  /// Cerrar sesión
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Cerrar sesión'),
          ],
        ),
        content: const Text('¿Está seguro de que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () {
              widget.authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  /// Manejar selección del menú de usuario (desktop)
  void _handleUserMenuSelection(String value) {
    switch (value) {
      case 'schedules':
        _navigateToSchedules();
        break;
      case 'change_username':
        UserDialogs.showChangeUsernameDialog(context, widget.authService, () => setState(() {}));
        break;
      case 'change_password':
        _showChangePassword();
        break;
      case 'add_user':
        UserDialogs.showAddUserDialog(context, widget.authService);
        break;
      case 'view_users':
        _showUsersManagement();
        break;
      case 'audit':
        _navigateToAudit();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.grey.shade50,
          appBar: _buildAppBar(isDesktop),
          drawer: isDesktop ? null : DashboardDrawer(
            username: widget.authService.currentUser?['username'] ?? 'Usuario',
            onSchedules: _navigateToSchedules,
            onUsers: _showUsersManagement,
            onChangePassword: _showChangePassword,
            onAuditLogs: _navigateToAudit,
            onLogout: _handleLogout,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await _checkDbConnection();
              await _loadDashboardData();
              await _loadAuditLogs();
            },
            child: isDesktop
                ? DesktopDashboardLayout(
                    visitsCount: _visitsCount,
                    dailyDepartures: _dailyDepartures,
                    isDbConnected: _isDbConnected,
                    lastDbCheck: _lastDbCheck,
                    auditLogs: _auditLogs,
                    onViewAllLogs: _navigateToAudit,
                    totalRoutes: _totalRoutes,
                    activeUsers: _activeUsers,
                  )
                : MobileDashboardLayout(
                    visitsCount: _visitsCount,
                    dailyDepartures: _dailyDepartures,
                    isDbConnected: _isDbConnected,
                    lastDbCheck: _lastDbCheck,
                    auditLogs: _auditLogs,
                    onViewAllLogs: _navigateToAudit,
                  ),
          ),
        );
      },
    );
  }

  /// Construir AppBar según plataforma
  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    if (isDesktop) {
      return _buildDesktopAppBar();
    } else {
      return _buildMobileAppBar();
    }
  }

  /// AppBar para móvil con hamburger menu
  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualizar',
          onPressed: () async {
            await _checkDbConnection();
            await _loadDashboardData();
            await _loadAuditLogs();
            await _loadVisitasHoy();
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// AppBar para escritorio con menú completo
  PreferredSizeWidget _buildDesktopAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Panel de Administración',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              Text(
                'Sistema de gestión de horarios',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Toggle modo oscuro/claro
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, themeMode, _) {
            final isDark = themeMode == ThemeMode.dark;
            return IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
              ),
              tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
              onPressed: () {
                themeNotifier.value =
                    isDark ? ThemeMode.light : ThemeMode.dark;
              },
            );
          },
        ),
        const SizedBox(width: 4),

        // Botón de horarios
        TextButton.icon(
          onPressed: _navigateToSchedules,
          icon: const Icon(Icons.schedule_rounded, size: 18),
          label: const Text('Horarios'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),

        // Menú de administración
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_rounded, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
              ],
            ),
          ),
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: _handleUserMenuSelection,
          itemBuilder: (context) => [
            _buildPopupItem('view_users', Icons.group_rounded, 'Ver usuarios'),
            _buildPopupItem('add_user', Icons.person_add_rounded, 'Agregar usuario'),
            const PopupMenuDivider(),
            _buildPopupItem('change_username', Icons.badge_rounded, 'Cambiar nombre'),
            _buildPopupItem('change_password', Icons.lock_rounded, 'Cambiar contraseña'),
            const PopupMenuDivider(),
            _buildPopupItem('audit', Icons.history_rounded, 'Auditoría'),
          ],
        ),
        const SizedBox(width: 8),

        // Usuario actual y logout
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  widget.authService.currentUser?['username'] ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: _handleUserMenuSelection,
          itemBuilder: (context) => [
            _buildPopupItem('logout', Icons.logout_rounded, 'Cerrar sesión', isDestructive: true),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? AppColors.error : AppColors.darkGrey),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDestructive ? AppColors.error : AppColors.darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
