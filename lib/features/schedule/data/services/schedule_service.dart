import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar los horarios de buses desde Firestore
class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de horarios (DocumentSnapshot) para comuna y tipo de día
  Stream<List<DocumentSnapshot>> getScheduleStream(String comuna, String dayType) {
    return _firestore
        .collection('horarios')
        .doc(comuna)
        .collection(dayType)
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Agregar un nuevo horario
  Future<void> addScheduleEntry(String comuna, String dayType, String time) async {
    await _firestore
        .collection('horarios')
        .doc(comuna)
        .collection(dayType)
        .add({
      'time': time,
    });
  }

  /// Actualizar un horario existente
  Future<void> updateScheduleEntry(DocumentReference ref, String time) async {
    await ref.update({
      'time': time,
    });
  }

  /// Eliminar un horario
  Future<void> deleteScheduleEntry(DocumentReference ref) async {
    await ref.delete();
  }
}
