import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Modelo para un registro de auditoría
class AuditLog {
  final String id;
  final String actionType;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? newValue;
  final Map<String, dynamic>? oldValue;
  final DateTime timestamp;
  final String username;

  AuditLog({
    required this.id,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    this.newValue,
    this.oldValue,
    required this.timestamp,
    required this.username,
  });

  /// Crear desde documento de Firestore
  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final details = data['details'] as Map<String, dynamic>? ?? {};
    
    return AuditLog(
      id: doc.id,
      actionType: data['actionType'] ?? 'unknown',
      entityType: details['entityType'] ?? 'unknown',
      entityId: details['entityId'] ?? '',
      newValue: details['newValue'] as Map<String, dynamic>?,
      oldValue: details['oldValue'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      username: data['username'] ?? 'Sistema',
    );
  }

  /// Obtener descripción legible de la acción
  String get actionDescription {
    final entityName = _getEntityName();
    
    switch (actionType) {
      case 'create':
        return 'Horario agregado: $entityName';
      case 'update':
        return 'Horario editado: $entityName';
      case 'delete':
        return 'Horario eliminado: $entityName';
      case 'login':
        return 'Inicio de sesión';
      case 'logout':
        return 'Cierre de sesión';
      case 'user_create':
        return 'Usuario creado: $entityName';
      case 'user_delete':
        return 'Usuario eliminado: $entityName';
      case 'password_change':
        return 'Contraseña cambiada';
      default:
        return 'Acción: $actionType';
    }
  }

  /// Obtener nombre de la entidad afectada
  String _getEntityName() {
    if (newValue != null) {
      final time = newValue!['time'] ?? '';
      final dayType = newValue!['dayType'] ?? '';
      if (time.isNotEmpty) {
        return '$time (${_formatDayType(dayType)})';
      }
    }
    if (oldValue != null) {
      final time = oldValue!['time'] ?? '';
      final dayType = oldValue!['dayType'] ?? '';
      if (time.isNotEmpty) {
        return '$time (${_formatDayType(dayType)})';
      }
    }
    // Para entityType como horario_aysen, extraer origen
    if (entityType.startsWith('horario_')) {
      final origen = entityType.replaceFirst('horario_', '');
      return _formatOrigen(origen);
    }
    return entityId.isNotEmpty ? entityId : entityType;
  }

  String _formatDayType(String dayType) {
    switch (dayType) {
      case 'weekday':
        return 'L-V';
      case 'saturday':
        return 'Sáb';
      case 'domingosFeriados':
        return 'Dom/Fer';
      default:
        return dayType;
    }
  }

  String _formatOrigen(String origen) {
    switch (origen.toLowerCase()) {
      case 'aysen':
        return 'Aysén';
      case 'coyhaique':
        return 'Coyhaique';
      case 'limache':
        return 'Limache';
      default:
        return origen;
    }
  }

  /// Obtener tiempo formateado relativo o absoluto
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Ahora';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} hora${diff.inHours > 1 ? 's' : ''}';
    } else if (diff.inDays == 1) {
      return 'Ayer ${_formatHour(timestamp)}';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${_formatHour(timestamp)}';
    }
  }

  String _formatHour(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Obtener ícono según tipo de acción
  IconData get icon {
    switch (actionType) {
      case 'create':
        return Icons.add_circle_rounded;
      case 'update':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_rounded;
      case 'login':
        return Icons.login_rounded;
      case 'logout':
        return Icons.logout_rounded;
      case 'user_create':
        return Icons.person_add_rounded;
      case 'user_delete':
        return Icons.person_remove_rounded;
      case 'password_change':
        return Icons.lock_reset_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  /// Obtener color según tipo de acción
  Color get color {
    switch (actionType) {
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.primary;
      case 'delete':
        return AppColors.error;
      case 'login':
        return AppColors.success;
      case 'logout':
        return Colors.grey;
      case 'user_create':
        return AppColors.secondary;
      case 'user_delete':
        return AppColors.error;
      case 'password_change':
        return Colors.orange;
      default:
        return AppColors.secondary;
    }
  }
}

/// Servicio para gestionar logs de auditoría
class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener stream de los últimos logs de auditoría
  Stream<List<AuditLog>> getAuditLogsStream({int limit = 50}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList());
  }

  /// Obtener logs de auditoría una vez
  Future<List<AuditLog>> getAuditLogs({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
  }

  /// Registrar una acción de auditoría
  Future<void> logAction({
    required String actionType,
    required String entityType,
    required String entityId,
    required String username,
    Map<String, dynamic>? newValue,
    Map<String, dynamic>? oldValue,
  }) async {
    await _firestore.collection('audit_logs').add({
      'actionType': actionType,
      'details': {
        'entityType': entityType,
        'entityId': entityId,
        'newValue': newValue,
        'oldValue': oldValue,
      },
      'timestamp': FieldValue.serverTimestamp(),
      'username': username,
    });
  }
}
