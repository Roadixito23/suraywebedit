import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para leer estadísticas desde Firestore.
///
/// Estructura en Firestore:
///   estadisticas/visitas
///     cantidadVisitas: 449   (int, total de visitas)
///     ultimaActualizacion:   (Timestamp)
class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _collection = 'estadisticas';
  static const _docId = 'visitas';

  /// Lee el total de visitas desde estadisticas/visitas.
  /// Retorna 0 si el documento no existe o hay un error.
  Future<int> getVisitas() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_docId).get();
      if (!doc.exists) return 0;
      return (doc.data()?['cantidadVisitas'] as num?)?.toInt() ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
