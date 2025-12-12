import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_colors.dart';
import 'services/auth_service.dart';
import 'login_page.dart';

class SchedulePage extends StatefulWidget {
  final AuthService authService;

  const SchedulePage({Key? key, required this.authService}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with SingleTickerProviderStateMixin {
  late final FirebaseFirestore _firestore;
  bool _isEditing = false;
  late TabController _tabController;

  // Constantes de colores unificados
  static const Color _primaryColor = AppColors.primary;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Stream de horarios (DocumentSnapshot) para comuna y tipo de día
  Stream<List<DocumentSnapshot>> _timesDocsStream(String comuna, String dayType) {
    return _firestore
        .collection('horarios')
        .doc(comuna)
        .collection(dayType)
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Validación de formato HH:MM
  bool _isTimeFormatValid(String value) {
    // Verifica el formato HH:MM con expresión regular
    final RegExp regex = RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9])$');
    return regex.hasMatch(value);
  }

  /// Formateador de texto mejorado para horarios
  TextInputFormatter _createTimeInputFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      // Obtener solo dígitos
      String newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      String oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');

      // Limitar a 4 dígitos
      if (newDigits.length > 4) {
        newDigits = newDigits.substring(0, 4);
      }

      // Formatear el texto
      String formatted = '';
      if (newDigits.isEmpty) {
        formatted = '';
      } else if (newDigits.length <= 2) {
        formatted = newDigits;
      } else {
        formatted = '${newDigits.substring(0, 2)}:${newDigits.substring(2)}';
      }

      // Determinar la posición del cursor
      int selectionIndex = formatted.length;

      // Si se está borrando y el cursor está justo después del ":", mover el cursor antes del ":"
      if (newDigits.length < oldDigits.length && newValue.selection.baseOffset == 3 && formatted.length >= 3) {
        selectionIndex = 2; // Colocar cursor antes del ":"
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    });
  }

  /// Agregar un nuevo horario con validación mejorada
  Future<void> _addTimeEntry(String comuna, String dayType) async {
    final TextEditingController timeController = TextEditingController();
    bool isValidFormat = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Agregar nuevo horario',
            style: TextStyle(color: _primaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Horario para ${comuna == 'aysen' ? 'Aysén' : 'Coyhaique'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Formato HH:MM',
                  hintText: 'Ej: 08:30',
                  errorText: timeController.text.isNotEmpty && !isValidFormat
                      ? 'Formato inválido. Use HH:MM (ej: 09:30)'
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  _createTimeInputFormatter(),
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (value) {
                  setState(() {
                    isValidFormat = _isTimeFormatValid(value);
                  });
                },
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
                final String timeValue = timeController.text;
                if (timeValue.isNotEmpty && _isTimeFormatValid(timeValue)) {
                  try {
                    await _firestore
                        .collection('horarios')
                        .doc(comuna)
                        .collection(dayType)
                        .add({
                      'time': timeValue,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Horario agregado correctamente'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } else {
                  setState(() {
                    isValidFormat = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Editar un horario existente con validación mejorada
  Future<void> _editTimeEntry(String comuna, String dayType, DocumentSnapshot doc) async {
    final TextEditingController timeController = TextEditingController(
      text: (doc.data() as Map<String, dynamic>)['time'] as String,
    );
    bool isValidFormat = _isTimeFormatValid(timeController.text);

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Editar horario',
            style: TextStyle(color: _primaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Horario para ${comuna == 'aysen' ? 'Aysén' : 'Coyhaique'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Formato HH:MM',
                  hintText: 'Ej: 08:30',
                  errorText: timeController.text.isNotEmpty && !isValidFormat
                      ? 'Formato inválido. Use HH:MM (ej: 09:30)'
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  _createTimeInputFormatter(),
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (value) {
                  setState(() {
                    isValidFormat = _isTimeFormatValid(value);
                  });
                },
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
                final String timeValue = timeController.text;
                if (timeValue.isNotEmpty && _isTimeFormatValid(timeValue)) {
                  try {
                    await doc.reference.update({
                      'time': timeValue,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Horario actualizado correctamente'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } else {
                  setState(() {
                    isValidFormat = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Eliminar un horario
  Future<void> _deleteTimeEntry(String comuna, DocumentSnapshot doc) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar horario',
          style: TextStyle(color: AppColors.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '¿Está seguro de eliminar el horario ${(doc.data() as Map<String, dynamic>)['time']}?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              try {
                await doc.reference.delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Horario eliminado correctamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Maneja las selecciones del menú de usuario
  void _handleUserMenuSelection(String value) {
    switch (value) {
      case 'username':
        // No hacer nada, solo muestra la información
        break;
      case 'change_username':
        _showChangeUsernameDialog();
        break;
      case 'change_password':
        _showChangePasswordDialog();
        break;
      case 'add_user':
        _showAddUserDialog();
        break;
      case 'view_users':
        _showAllUsersDialog();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  /// Diálogo para cambiar nombre de usuario
  Future<void> _showChangeUsernameDialog() async {
    final TextEditingController newUsernameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar nombre de usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Usuario actual: ${widget.authService.currentUser?['username']}'),
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

              final success = await widget.authService.changeUsername(newUsername);
              if (mounted) {
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
                  setState(() {}); // Actualizar UI
                }
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
  Future<void> _showChangePasswordDialog() async {
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

              final success = await widget.authService.changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Contraseña actualizada correctamente'
                        : 'Error: contraseña actual incorrecta'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para agregar nuevo usuario
  Future<void> _showAddUserDialog() async {
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

              final success = await widget.authService.createUser(username, password);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Usuario creado correctamente'
                        : 'Error: el usuario ya existe'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para ver todos los usuarios
  Future<void> _showAllUsersDialog() async {
    final users = await widget.authService.getAllUsers();

    if (!mounted) return;

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
                    final isCurrentUser = user['id'] == widget.authService.currentUser?['id'];

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
                                onPressed: () => _confirmDeleteUser(user['id'], user['username']),
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
  Future<void> _confirmDeleteUser(String userId, String username) async {
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
              final success = await widget.authService.deleteUser(userId);
              if (mounted) {
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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Formatear timestamp de Firestore
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dateTime = (timestamp as Timestamp).toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Manejar logout
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Está seguro de cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  /// Construye una tarjeta de horarios para un tipo de día
  Widget _buildScheduleCard(String title, String comuna, String dayType, Color headerColor) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _timesDocsStream(comuna, dayType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(title);
        }

        if (snapshot.hasError) {
          return _buildErrorCard(title, snapshot.error.toString());
        }

        final docs = snapshot.data;
        if (docs == null || docs.isEmpty) {
          return _buildEmptyCard(title, comuna, dayType);
        }

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
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        onPressed: () => _addTimeEntry(comuna, dayType),
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
                        trailing: _isEditing
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: _primaryColor),
                              onPressed: () => _editTimeEntry(comuna, dayType, doc),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _deleteTimeEntry(comuna, doc),
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
      },
    );
  }

  /// Widget para mostrar cargando
  Widget _buildLoadingCard(String title) {
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
  Widget _buildErrorCard(String title, String error) {
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
  Widget _buildEmptyCard(String title, String comuna, String dayType) {
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
            if (_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _addTimeEntry(comuna, dayType),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Horarios Aysén y Coyhaique',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: _primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(
              icon: Icon(Icons.departure_board),
              text: 'Aysén',
            ),
            Tab(
              icon: Icon(Icons.departure_board),
              text: 'Coyhaique',
            ),
          ],
        ),
        actions: [
          // Botón para alternar modo edición
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? 'Terminar edición' : 'Editar horarios',
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isEditing
                      ? 'Modo edición activado'
                      : 'Modo edición desactivado'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
          // Menú de usuario
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Gestión de usuario',
            onSelected: _handleUserMenuSelection,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'username',
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 12),
                    Text('Usuario: ${widget.authService.currentUser?['username'] ?? 'N/A'}'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'change_username',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.secondary, size: 20),
                    SizedBox(width: 12),
                    Text('Cambiar nombre de usuario'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.secondary, size: 20),
                    SizedBox(width: 12),
                    Text('Cambiar contraseña'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_user',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppColors.success, size: 20),
                    SizedBox(width: 12),
                    Text('Agregar nuevo usuario'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_users',
                child: Row(
                  children: [
                    Icon(Icons.group, color: AppColors.secondary, size: 20),
                    SizedBox(width: 12),
                    Text('Ver todos los usuarios'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: AppColors.error, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5EE), Color(0xFFF0F8FF)], // Gradiente suave naranja-azul
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab de Aysén
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado informativo
                  Card(
                    color: _primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salidas desde Aysén',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Horarios de buses con destino a Coyhaique',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tarjetas de horarios de Aysén
                  _buildScheduleCard('Lunes a Viernes', 'aysen', 'lunesViernes', _primaryColor),
                  _buildScheduleCard('Sábados', 'aysen', 'sabados', _primaryColor),
                  _buildScheduleCard('Domingos y Feriados', 'aysen', 'domingosFeriados', _primaryColor),
                ],
              ),
            ),

            // Tab de Coyhaique
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado informativo
                  Card(
                    color: _primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salidas desde Coyhaique',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Horarios de buses con destino a Aysén',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tarjetas de horarios de Coyhaique
                  _buildScheduleCard('Lunes a Viernes', 'coyhaique', 'lunesViernes', _primaryColor),
                  _buildScheduleCard('Sábados', 'coyhaique', 'sabados', _primaryColor),
                  _buildScheduleCard('Domingos y Feriados', 'coyhaique', 'domingosFeriados', _primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}