import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/modern_schedule_card.dart';

/// Widget que muestra el layout de horarios para móvil
/// Presenta las 3 tablas apiladas verticalmente con diseño modernizado
class MobileScheduleLayout extends StatelessWidget {
  final String comuna;
  final String comunaDisplayName;
  final String destinoDisplayName;
  final bool isEditing;
  final Stream<List<DocumentSnapshot>> Function(String comuna, String dayType) streamBuilder;
  final Future<void> Function(String comuna, String dayType) onAdd;
  final Future<void> Function(String comuna, String dayType, DocumentSnapshot doc) onEdit;
  final Future<void> Function(String comuna, DocumentSnapshot doc) onDelete;

  const MobileScheduleLayout({
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header compacto para móvil
          _buildMobileHeader(),
          const SizedBox(height: 16),

          // Tarjetas de horarios apiladas
          ModernScheduleCard(
            title: 'Lunes a Viernes',
            subtitle: '5 días laborales',
            icon: Icons.work_outline_rounded,
            stream: streamBuilder(comuna, 'lunesViernes'),
            isEditing: isEditing,
            onAdd: () => onAdd(comuna, 'lunesViernes'),
            onEdit: (doc) => onEdit(comuna, 'lunesViernes', doc),
            onDelete: (doc) => onDelete(comuna, doc),
          ),
          
          ModernScheduleCard(
            title: 'Sábados',
            subtitle: 'Fin de semana',
            icon: Icons.weekend_outlined,
            stream: streamBuilder(comuna, 'sabados'),
            isEditing: isEditing,
            onAdd: () => onAdd(comuna, 'sabados'),
            onEdit: (doc) => onEdit(comuna, 'sabados', doc),
            onDelete: (doc) => onDelete(comuna, doc),
          ),
          
          ModernScheduleCard(
            title: 'Domingos y Feriados',
            subtitle: 'Días festivos',
            icon: Icons.celebration_outlined,
            stream: streamBuilder(comuna, 'domingosFeriados'),
            isEditing: isEditing,
            onAdd: () => onAdd(comuna, 'domingosFeriados'),
            onEdit: (doc) => onEdit(comuna, 'domingosFeriados', doc),
            onDelete: (doc) => onDelete(comuna, doc),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icono de ubicación
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desde $comunaDisplayName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Destino: $destinoDisplayName',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Badge de bus
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: AppColors.secondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
