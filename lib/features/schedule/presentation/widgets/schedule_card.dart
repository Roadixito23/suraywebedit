import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget de tarjeta para mostrar horarios de un tipo de día
class ScheduleCard extends StatelessWidget {
  final String title;
  final Stream<List<DocumentSnapshot>> stream;
  final bool isEditing;
  final VoidCallback onAdd;
  final Function(DocumentSnapshot) onEdit;
  final Function(DocumentSnapshot) onDelete;

  static const Color _primaryColor = AppColors.primary;

  const ScheduleCard({
    Key? key,
    required this.title,
    required this.stream,
    required this.isEditing,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

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

        return _buildScheduleCard(docs);
      },
    );
  }

  Widget _buildScheduleCard(List<DocumentSnapshot> docs) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado de la tarjeta
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    onPressed: onAdd,
                    tooltip: 'Agregar horario',
                  ),
              ],
            ),
          ),

          // Cuerpo de la tarjeta con horarios
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final time = (doc.data() as Map<String, dynamic>)['time'] as String;

                return Container(
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                    border: index != docs.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1.0,
                            ),
                          )
                        : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: _primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    dense: true,
                    trailing: isEditing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: _primaryColor),
                                onPressed: () => onEdit(doc),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () => onDelete(doc),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar cargando
  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Cargando horarios para $title...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar error
  Widget _buildErrorCard(String error) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Error cargando "$title"',
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
            Text(
              error,
              style: const TextStyle(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar cuando no hay horarios
  Widget _buildEmptyCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: _primaryColor, size: 48),
            const SizedBox(height: 12),
            Text(
              'No hay horarios disponibles para "$title"',
              style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Agregar horario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
