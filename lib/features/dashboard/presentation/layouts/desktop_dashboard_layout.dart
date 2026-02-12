import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/dashboard_cards.dart';

/// Layout del dashboard para escritorio - más técnico y denso
class DesktopDashboardLayout extends StatelessWidget {
  final int visitsCount;
  final int dailyDepartures;
  final bool isDbConnected;
  final String lastDbCheck;
  final List<AuditLogEntry> auditLogs;
  final VoidCallback onViewAllLogs;
  
  // Estadísticas adicionales para desktop
  final int totalRoutes;
  final int activeUsers;

  const DesktopDashboardLayout({
    super.key,
    required this.visitsCount,
    required this.dailyDepartures,
    required this.isDbConnected,
    required this.lastDbCheck,
    required this.auditLogs,
    required this.onViewAllLogs,
    this.totalRoutes = 0,
    this.activeUsers = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panel de Control',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Resumen del sistema en tiempo real',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                width: 280,
                child: CurrentDateCard(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Fila de estadísticas principales
          Row(
            children: [
              Expanded(
                child: _TechStatCard(
                  label: 'VISITAS HOY',
                  value: visitsCount.toString(),
                  trend: '+12.5%',
                  trendUp: true,
                  icon: Icons.visibility_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TechStatCard(
                  label: 'SALIDAS DEL DÍA',
                  value: dailyDepartures.toString(),
                  trend: 'Programadas',
                  trendUp: true,
                  icon: Icons.departure_board_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TechStatCard(
                  label: 'RUTAS ACTIVAS',
                  value: totalRoutes.toString(),
                  trend: '3 orígenes',
                  trendUp: true,
                  icon: Icons.route_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TechStatCard(
                  label: 'USUARIOS',
                  value: activeUsers.toString(),
                  trend: 'Registrados',
                  trendUp: true,
                  icon: Icons.group_rounded,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Segunda fila: Estado de conexión y Logs
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel de estado del sistema
              Expanded(
                flex: 2,
                child: _SystemStatusPanel(
                  isDbConnected: isDbConnected,
                  lastDbCheck: lastDbCheck,
                ),
              ),
              const SizedBox(width: 16),
              // Panel de auditoría
              Expanded(
                flex: 3,
                child: _TechAuditPanel(
                  logs: auditLogs,
                  onViewAll: onViewAllLogs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de estadística estilo técnico para desktop
class _TechStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final IconData icon;
  final Color color;

  const _TechStatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: trendUp ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Panel de estado del sistema para desktop
class _SystemStatusPanel extends StatelessWidget {
  final bool isDbConnected;
  final String lastDbCheck;

  const _SystemStatusPanel({
    required this.isDbConnected,
    required this.lastDbCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_rounded, 
                color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Estado del Sistema',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGrey,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDbConnected 
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDbConnected ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isDbConnected ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDbConnected ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatusRow(
            'Firebase Firestore',
            isDbConnected ? 'Conectado' : 'Desconectado',
            isDbConnected,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Autenticación',
            isDbConnected ? 'Activa' : 'Inactiva',
            isDbConnected,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Última sincronización',
            lastDbCheck,
            true,
            showIndicator: false,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, 
                size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Sistema operando con normalidad',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, bool isOk, {bool showIndicator = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        Row(
          children: [
            if (showIndicator) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isOk ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOk ? AppColors.darkGrey : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Panel de auditoría estilo técnico para desktop
class _TechAuditPanel extends StatelessWidget {
  final List<AuditLogEntry> logs;
  final VoidCallback onViewAll;

  const _TechAuditPanel({
    required this.logs,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, 
                    color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Registro de Actividad',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Ver todo'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Header de tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'ACCIÓN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'USUARIO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'HORA',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Lista de logs
          ...logs.map((log) => _buildLogRow(log)),
        ],
      ),
    );
  }

  Widget _buildLogRow(AuditLogEntry log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: log.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(log.icon, size: 14, color: log.color),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    log.action,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.user,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.time,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
