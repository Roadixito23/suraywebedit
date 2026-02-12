import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/dashboard_cards.dart';
import '../../data/services/audit_service.dart';

/// Página de auditoría completa
class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  final AuditService _auditService = AuditService();
  
  List<AuditLogEntry> _allLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _auditService.getAuditLogs(limit: 100);
      if (mounted) {
        setState(() {
          _allLogs = logs.map((log) => AuditLogEntry(
            action: log.actionDescription,
            user: log.username,
            time: log.formattedTime,
            icon: log.icon,
            color: log.color,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error cargando audit logs: $e');
    }
  }

  List<AuditLogEntry> get _filteredLogs {
    var logs = _allLogs;

    // Filtrar por tipo
    if (_selectedFilter != 'all') {
      logs = logs.where((log) {
        switch (_selectedFilter) {
          case 'auth':
            return log.action.contains('sesión') || log.action.contains('Contraseña');
          case 'schedules':
            return log.action.contains('Horario');
          case 'users':
            return log.action.contains('Usuario');
          default:
            return true;
        }
      }).toList();
    }

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      logs = logs.where((log) => 
        log.action.toLowerCase().contains(search) ||
        log.user.toLowerCase().contains(search)
      ).toList();
    }

    return logs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Registro de Auditoría'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Exportar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de exportar próximamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra de filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Búsqueda
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar en los registros...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Chips de filtro
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Todos', Icons.list_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('auth', 'Autenticación', Icons.lock_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('schedules', 'Horarios', Icons.schedule_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('users', 'Usuarios', Icons.group_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${_filteredLogs.length} registros encontrados',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Lista de logs
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredLogs.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadAuditLogs,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        return _buildLogItem(_filteredLogs[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 16,
            color: isSelected ? Colors.white : AppColors.darkGrey,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.darkGrey,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildLogItem(AuditLogEntry log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: log.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(log.icon, color: log.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_rounded, 
                      size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      log.user,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time_rounded, 
                      size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      log.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron registros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
