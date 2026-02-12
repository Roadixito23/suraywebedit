import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/modern_schedule_card.dart';

/// Widget que muestra el layout de horarios para desktop
/// Presenta las 3 tablas (Lunes-Viernes, Sábados, Domingos) en una fila
class DesktopScheduleLayout extends StatelessWidget {
  final String comuna;
  final String comunaDisplayName;
  final String destinoDisplayName;
  final bool isEditing;
  final Stream<List<DocumentSnapshot>> Function(String comuna, String dayType) streamBuilder;
  final Future<void> Function(String comuna, String dayType) onAdd;
  final Future<void> Function(String comuna, String dayType, DocumentSnapshot doc) onEdit;
  final Future<void> Function(String comuna, DocumentSnapshot doc) onDelete;

  const DesktopScheduleLayout({
    super.key,
    required this.comuna,
    required this.comunaDisplayName,
    required this.destinoDisplayName,
    required this.isEditing,
    required this.streamBuilder,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información de la ruta
          _buildRouteHeader(),
          const SizedBox(height: 24),
          
          // Grid con las 3 tarjetas de horarios
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lunes a Viernes
              Expanded(
                child: ModernScheduleCard(
                  title: 'Lunes a Viernes',
                  subtitle: '5 días laborales',
                  icon: Icons.work_outline_rounded,
                  stream: streamBuilder(comuna, 'lunesViernes'),
                  isEditing: isEditing,
                  isCompact: true,
                  onAdd: () => onAdd(comuna, 'lunesViernes'),
                  onEdit: (doc) => onEdit(comuna, 'lunesViernes', doc),
                  onDelete: (doc) => onDelete(comuna, doc),
                ),
              ),
              const SizedBox(width: 20),
              
              // Sábados
              Expanded(
                child: ModernScheduleCard(
                  title: 'Sábados',
                  subtitle: 'Fin de semana',
                  icon: Icons.weekend_outlined,
                  stream: streamBuilder(comuna, 'sabados'),
                  isEditing: isEditing,
                  isCompact: true,
                  onAdd: () => onAdd(comuna, 'sabados'),
                  onEdit: (doc) => onEdit(comuna, 'sabados', doc),
                  onDelete: (doc) => onDelete(comuna, doc),
                ),
              ),
              const SizedBox(width: 20),
              
              // Domingos y Feriados
              Expanded(
                child: ModernScheduleCard(
                  title: 'Domingos y Feriados',
                  subtitle: 'Días festivos',
                  icon: Icons.celebration_outlined,
                  stream: streamBuilder(comuna, 'domingosFeriados'),
                  isEditing: isEditing,
                  isCompact: true,
                  onAdd: () => onAdd(comuna, 'domingosFeriados'),
                  onEdit: (doc) => onEdit(comuna, 'domingosFeriados', doc),
                  onDelete: (doc) => onDelete(comuna, doc),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icono de origen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          
          // Información de la ruta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salidas desde $comunaDisplayName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Destino: $destinoDisplayName',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Indicador de ruta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  comunaDisplayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  destinoDisplayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
