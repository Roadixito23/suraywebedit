import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../widgets/schedule_card.dart';
import '../widgets/user_dialogs.dart';

class SchedulePage extends StatefulWidget {
  final AuthService authService;

  const SchedulePage({Key? key, required this.authService}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
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
        UserDialogs.showChangeUsernameDialog(context, widget.authService, () => setState(() {}));
        break;
      case 'change_password':
        UserDialogs.showChangePasswordDialog(context, widget.authService);
        break;
      case 'add_user':
        UserDialogs.showAddUserDialog(context, widget.authService);
        break;
      case 'view_users':
        UserDialogs.showAllUsersDialog(context, widget.authService);
        break;
      case 'logout':
        _handleLogout();
        break;
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
                  ScheduleCard(
                    title: 'Lunes a Viernes',
                    stream: _timesDocsStream('aysen', 'lunesViernes'),
                    isEditing: _isEditing,
                    onAdd: () => _addTimeEntry('aysen', 'lunesViernes'),
                    onEdit: (doc) => _editTimeEntry('aysen', 'lunesViernes', doc),
                    onDelete: (doc) => _deleteTimeEntry('aysen', doc),
                  ),
                  ScheduleCard(
                    title: 'Sábados',
                    stream: _timesDocsStream('aysen', 'sabados'),
                    isEditing: _isEditing,
                    onAdd: () => _addTimeEntry('aysen', 'sabados'),
                    onEdit: (doc) => _editTimeEntry('aysen', 'sabados', doc),
                    onDelete: (doc) => _deleteTimeEntry('aysen', doc),
                  ),
                  ScheduleCard(
                    title: 'Domingos y Feriados',
                    stream: _timesDocsStream('aysen', 'domingosFeriados'),
                    isEditing: _isEditing,
                    onAdd: () => _addTimeEntry('aysen', 'domingosFeriados'),
                    onEdit: (doc) => _editTimeEntry('aysen', 'domingosFeriados', doc),
                    onDelete: (doc) => _deleteTimeEntry('aysen', doc),
                  ),
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
                  ScheduleCard(
                    title: 'Lunes a Viernes',
                    stream: _timesDocsStream('coyhaique', 'lunesViernes'),
                    isEditing: _isEditing,
                    onAdd: () => _addTimeEntry('coyhaique', 'lunesViernes'),
                    onEdit: (doc) => _editTimeEntry('coyhaique', 'lunesViernes', doc),
                    onDelete: (doc) => _deleteTimeEntry('coyhaique', doc),
                  ),
                  ScheduleCard(
                    title: 'Sábados',
                    stream: _timesDocsStream('coyhaique', 'sabados'),
                    isEditing: _isEditing,
                    onAdd: () => _addTimeEntry('coyhaique', 'sabados'),
                    onEdit: (doc) => _editTimeEntry('coyhaique', 'sabados', doc),
                    onDelete: (doc) => _deleteTimeEntry('coyhaique', doc),
                  ),
                  ScheduleCard(
                    title: 'Domingos y Feriados',
                    stream: _timesDocsStream('coyhaique', 'domingosFeriados'),
                    isEditing: _isEditing,
                    onAdd: () => _addTimeEntry('coyhaique', 'domingosFeriados'),
                    onEdit: (doc) => _editTimeEntry('coyhaique', 'domingosFeriados', doc),
                    onDelete: (doc) => _deleteTimeEntry('coyhaique', doc),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
