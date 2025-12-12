import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usuario actualmente autenticado
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Hash de contraseña usando SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Login de usuario
  Future<bool> login(String username, String password) async {
    try {
      // Buscar usuario por nombre de usuario
      final querySnapshot = await _firestore
          .collection('admin_users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // Usuario no encontrado
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final storedPassword = userData['password'] as String;

      // Verificar contraseña hasheada
      final hashedInputPassword = _hashPassword(password);

      if (storedPassword == hashedInputPassword) {
        _currentUser = {
          'id': userDoc.id,
          'username': userData['username'],
          'createdAt': userData['createdAt'],
        };
        return true;
      }

      return false; // Contraseña incorrecta
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  // Logout
  void logout() {
    _currentUser = null;
  }

  // Obtener todos los usuarios (sin contraseñas)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('admin_users')
          .orderBy('username')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'username': data['username'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Crear nuevo usuario
  Future<bool> createUser(String username, String password) async {
    try {
      // Verificar si el usuario ya existe
      final existingUser = await _firestore
          .collection('admin_users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return false; // Usuario ya existe
      }

      // Crear nuevo usuario con contraseña hasheada
      await _firestore.collection('admin_users').add({
        'username': username,
        'password': _hashPassword(password),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // Cambiar nombre de usuario
  Future<bool> changeUsername(String newUsername) async {
    if (_currentUser == null) return false;

    try {
      // Verificar que el nuevo nombre no exista
      final existingUser = await _firestore
          .collection('admin_users')
          .where('username', isEqualTo: newUsername)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return false; // Usuario ya existe
      }

      // Actualizar nombre de usuario
      await _firestore
          .collection('admin_users')
          .doc(_currentUser!['id'])
          .update({'username': newUsername});

      _currentUser!['username'] = newUsername;
      return true;
    } catch (e) {
      print('Error changing username: $e');
      return false;
    }
  }

  // Cambiar contraseña del usuario actual
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    try {
      // Obtener documento del usuario
      final userDoc = await _firestore
          .collection('admin_users')
          .doc(_currentUser!['id'])
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final storedPassword = userData['password'] as String;

      // Verificar contraseña actual
      if (storedPassword != _hashPassword(currentPassword)) {
        return false; // Contraseña actual incorrecta
      }

      // Actualizar con nueva contraseña hasheada
      await _firestore
          .collection('admin_users')
          .doc(_currentUser!['id'])
          .update({'password': _hashPassword(newPassword)});

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // Eliminar usuario (solo si no es el usuario actual)
  Future<bool> deleteUser(String userId) async {
    if (_currentUser == null || _currentUser!['id'] == userId) {
      return false; // No puede eliminar su propia cuenta
    }

    try {
      await _firestore.collection('admin_users').doc(userId).delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
