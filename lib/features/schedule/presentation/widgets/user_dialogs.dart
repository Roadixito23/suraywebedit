import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/services/auth_service.dart';

/// Clase con diálogos para gestión de usuarios
class UserDialogs {
  /// Diálogo para cambiar nombre de usuario
  static Future<void> showChangeUsernameDialog(
    BuildContext context,
    AuthService authService,
    VoidCallback onSuccess,
  ) async {
    final TextEditingController newUsernameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar nombre de usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Usuario actual: ${authService.currentUser?['username']}'),
            const SizedBox(height: 16),
            TextField(
              controller: newUsernameController,
              decoration: const InputDecoration(
                labelText: 'Nuevo nombre de usuario',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = newUsernameController.text.trim();
              if (newUsername.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre de usuario no puede estar vacío'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final success = await authService.changeUsername(newUsername);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Nombre de usuario actualizado correctamente'
                      : 'Error: el nombre de usuario ya existe'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
              if (success) {
                onSuccess();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para cambiar contraseña
  static Future<void> showChangePasswordDialog(
    BuildContext context,
    AuthService authService,
  ) async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Las contraseñas no coinciden'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La contraseña debe tener al menos 6 caracteres'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final success = await authService.changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Contraseña actualizada correctamente'
                      : 'Error: contraseña actual incorrecta'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para agregar nuevo usuario
  static Future<void> showAddUserDialog(
    BuildContext context,
    AuthService authService,
  ) async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nuevo usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = usernameController.text.trim();
              final password = passwordController.text;

              if (username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todos los campos son requeridos'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La contraseña debe tener al menos 6 caracteres'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final success = await authService.createUser(username, password);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Usuario creado correctamente'
                      : 'Error: el usuario ya existe'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para ver todos los usuarios
  static Future<void> showAllUsersDialog(
    BuildContext context,
    AuthService authService,
  ) async {
    final users = await authService.getAllUsers();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Todos los usuarios'),
        content: SizedBox(
          width: double.maxFinite,
          child: users.isEmpty
              ? const Text('No hay usuarios registrados')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isCurrentUser = user['id'] == authService.currentUser?['id'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentUser ? AppColors.primary : AppColors.secondary,
                          child: Text(
                            user['username'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['username']),
                        subtitle: Text(isCurrentUser ? 'Usuario actual' : 'Creado: ${_formatTimestamp(user['createdAt'])}'),
                        trailing: isCurrentUser
                            ? const Chip(
                                label: Text('Tú', style: TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.primaryLight,
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () => _confirmDeleteUser(context, authService, user['id'], user['username']),
                              ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Confirmar eliminación de usuario
  static Future<void> _confirmDeleteUser(
    BuildContext context,
    AuthService authService,
    String userId,
    String username,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Está seguro de eliminar al usuario "$username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await authService.deleteUser(userId);
              Navigator.pop(context); // Cerrar confirmación
              Navigator.pop(context); // Cerrar lista de usuarios
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Usuario eliminado correctamente'
                      : 'Error al eliminar usuario'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Formatear timestamp de Firestore
  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dateTime = (timestamp as Timestamp).toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
