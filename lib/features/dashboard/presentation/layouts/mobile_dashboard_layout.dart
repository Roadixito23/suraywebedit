import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../widgets/dashboard_cards.dart';

/// Layout del dashboard para dispositivos móviles
class MobileDashboardLayout extends StatelessWidget {
  final int visitsCount;
  final int dailyDepartures;
  final bool isDbConnected;
  final String lastDbCheck;
  final List<AuditLogEntry> auditLogs;
  final VoidCallback onViewAllLogs;

  const MobileDashboardLayout({
    super.key,
    required this.visitsCount,
    required this.dailyDepartures,
    required this.isDbConnected,
    required this.lastDbCheck,
    required this.auditLogs,
    required this.onViewAllLogs,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fecha actual
          const CurrentDateCard(),
          const SizedBox(height: 16),

          // Estado de conexión
          ConnectionStatusCard(
            isConnected: isDbConnected,
            lastCheck: lastDbCheck,
          ),
          const SizedBox(height: 16),

          // Estadísticas en grid 2x1
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Visitas hoy',
                  value: visitsCount.toString(),
                  subtitle: '+12%',
                  icon: Icons.visibility_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Salidas del día',
                  value: dailyDepartures.toString(),
                  subtitle: 'Programadas',
                  icon: Icons.departure_board_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Últimos logs de auditoría
          AuditLogCard(
            logs: auditLogs,
            onViewAll: onViewAllLogs,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Drawer para navegación móvil
class DashboardDrawer extends StatelessWidget {
  final String username;
  final VoidCallback onSchedules;
  final VoidCallback onUsers;
  final VoidCallback onChangePassword;
  final VoidCallback onAuditLogs;
  final VoidCallback onLogout;

  const DashboardDrawer({
    super.key,
    required this.username,
    required this.onSchedules,
    required this.onUsers,
    required this.onChangePassword,
    required this.onAuditLogs,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header del drawer
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Panel de Administración',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Opciones del menú
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSectionHeader('Principal'),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: true,
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.schedule_rounded,
                  label: 'Horarios',
                  onTap: () {
                    Navigator.pop(context);
                    onSchedules();
                  },
                ),
                _buildThemeToggleItem(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                
                _buildSectionHeader('Administración'),
                _buildDrawerItem(
                  icon: Icons.group_rounded,
                  label: 'Gestionar usuarios',
                  onTap: () {
                    Navigator.pop(context);
                    onUsers();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.lock_rounded,
                  label: 'Cambiar contraseña',
                  onTap: () {
                    Navigator.pop(context);
                    onChangePassword();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history_rounded,
                  label: 'Auditoría',
                  onTap: () {
                    Navigator.pop(context);
                    onAuditLogs();
                  },
                ),
              ],
            ),
          ),

          // Botón de cerrar sesión
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleItem() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                themeNotifier.value =
                    isDark ? ThemeMode.light : ThemeMode.dark;
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isDark ? 'Modo claro' : 'Modo oscuro',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: isDark,
                      onChanged: (value) {
                        themeNotifier.value =
                            value ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : Colors.grey.shade600,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.darkGrey,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
