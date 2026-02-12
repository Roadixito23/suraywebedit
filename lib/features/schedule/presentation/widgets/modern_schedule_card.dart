import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget de tarjeta modernizada para mostrar horarios de un tipo de día
class ModernScheduleCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Stream<List<DocumentSnapshot>> stream;
  final bool isEditing;
  final VoidCallback onAdd;
  final Function(DocumentSnapshot) onEdit;
  final Function(DocumentSnapshot) onDelete;
  final bool isCompact;

  const ModernScheduleCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.schedule,
    required this.stream,
    required this.isEditing,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }

        final docs = snapshot.data;
        if (docs == null || docs.isEmpty) {
          return _buildEmptyCard();
        }

        return _buildScheduleCard(context, docs);
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, List<DocumentSnapshot> docs) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 6.0 : 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado con gradiente moderno
          Container(
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 12 : 16,
              horizontal: isCompact ? 14 : 20,
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isCompact ? 20 : 24,
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 15 : 17,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: isCompact ? 11 : 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isEditing)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                    ),
                  ),
                if (!isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${docs.length} horarios',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de horarios modernizada
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade100,
              ),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final time = (doc.data() as Map<String, dynamic>)['time'] as String;

                return _buildTimeItem(context, doc, time, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(BuildContext context, DocumentSnapshot doc, String time, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEditing ? () => onEdit(doc) : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 20,
            vertical: isCompact ? 8 : 14,
          ),
          child: Row(
            children: [
              // Indicador de tiempo con efecto moderno - usando constraints en lugar de width fijo
              Container(
                constraints: BoxConstraints(
                  minWidth: isCompact ? 60 : 72,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isCompact ? 6 : 10,
                  horizontal: isCompact ? 10 : 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.1),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    time,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 10 : 16),
              // Información adicional - simplificada en modo compacto
              Expanded(
                child: isCompact 
                  ? Text(
                      'Salida',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGrey,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salida programada',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Horario regular',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                ),
              ),
              // Acciones de edición - más compactas
              if (isEditing) ...[
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    color: AppColors.secondary,
                    size: isCompact ? 18 : 22,
                  ),
                  onPressed: () => onEdit(doc),
                  tooltip: 'Editar horario',
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  constraints: BoxConstraints(
                    minWidth: isCompact ? 32 : 40,
                    minHeight: isCompact ? 32 : 40,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: isCompact ? 18 : 22,
                  ),
                  onPressed: () => onDelete(doc),
                  tooltip: 'Eliminar horario',
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  constraints: BoxConstraints(
                    minWidth: isCompact ? 32 : 40,
                    minHeight: isCompact ? 32 : 40,
                  ),
                ),
              ] else if (!isCompact)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade300,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para mostrar cargando
  Widget _buildLoadingCard() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 6.0 : 10.0),
      padding: EdgeInsets.all(isCompact ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: isCompact ? 32 : 40,
            height: isCompact ? 32 : 40,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando $title...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isCompact ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar error
  Widget _buildErrorCard(String error) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 6.0 : 10.0),
      padding: EdgeInsets.all(isCompact ? 20 : 24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: isCompact ? 28 : 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Error al cargar "$title"',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 14 : 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(
              color: AppColors.error.withValues(alpha: 0.7),
              fontSize: isCompact ? 12 : 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar cuando no hay horarios
  Widget _buildEmptyCard() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 6.0 : 10.0),
      padding: EdgeInsets.all(isCompact ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_outlined,
              color: AppColors.primary,
              size: isCompact ? 32 : 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin horarios',
            style: TextStyle(
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 15 : 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No hay horarios disponibles para $title',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isCompact ? 12 : 13,
            ),
            textAlign: TextAlign.center,
          ),
          if (isEditing) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Agregar horario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
