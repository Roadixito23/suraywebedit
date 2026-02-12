import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_breakpoints.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../layouts/desktop_schedule_layout.dart';
import '../layouts/mobile_schedule_layout.dart';
import '../widgets/user_dialogs.dart';

class SchedulePage extends StatefulWidget {
  final AuthService authService;

  const SchedulePage({super.key, required this.authService});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with SingleTickerProviderStateMixin {
  late final FirebaseFirestore _firestore;
  bool _isEditing = false;
  late TabController _tabController;

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
    final RegExp regex = RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9])$');
    return regex.hasMatch(value);
  }

  /// Formateador de texto mejorado para horarios
  TextInputFormatter _createTimeInputFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      String oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');

      if (newDigits.length > 4) {
        newDigits = newDigits.substring(0, 4);
      }

      String formatted = '';
      if (newDigits.isEmpty) {
        formatted = '';
      } else if (newDigits.length <= 2) {
        formatted = newDigits;
      } else {
        formatted = '${newDigits.substring(0, 2)}:${newDigits.substring(2)}';
      }

      int selectionIndex = formatted.length;

      if (newDigits.length < oldDigits.length && newValue.selection.baseOffset == 3 && formatted.length >= 3) {
        selectionIndex = 2;
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
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_alarm_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Text('Agregar horario'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      comuna == 'aysen' ? 'Aysén' : 'Coyhaique',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Hora de salida',
                  hintText: 'Ej: 08:30',
                  helperText: 'Formato: HH:MM (24 horas)',
                  errorText: timeController.text.isNotEmpty && !isValidFormat
                      ? 'Formato inválido'
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.access_time_rounded),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  _createTimeInputFormatter(),
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    isValidFormat = _isTimeFormatValid(value);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
            ),
            FilledButton.icon(
              onPressed: isValidFormat
                  ? () async {
                      final String timeValue = timeController.text;
                      try {
                        await _firestore
                            .collection('horarios')
                            .doc(comuna)
                            .collection(dayType)
                            .add({'time': timeValue});
                        Navigator.pop(context);
                        _showSuccessSnackBar('Horario agregado correctamente');
                      } catch (e) {
                        _showErrorSnackBar('Error: $e');
                      }
                    }
                  : null,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Guardar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Editar un horario existente
  Future<void> _editTimeEntry(String comuna, String dayType, DocumentSnapshot doc) async {
    final TextEditingController timeController = TextEditingController(
      text: (doc.data() as Map<String, dynamic>)['time'] as String,
    );
    bool isValidFormat = _isTimeFormatValid(timeController.text);

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              const Text('Editar horario'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      comuna == 'aysen' ? 'Aysén' : 'Coyhaique',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Hora de salida',
                  hintText: 'Ej: 08:30',
                  helperText: 'Formato: HH:MM (24 horas)',
                  errorText: timeController.text.isNotEmpty && !isValidFormat
                      ? 'Formato inválido'
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.access_time_rounded),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  _createTimeInputFormatter(),
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    isValidFormat = _isTimeFormatValid(value);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
            ),
            FilledButton.icon(
              onPressed: isValidFormat
                  ? () async {
                      final String timeValue = timeController.text;
                      try {
                        await doc.reference.update({'time': timeValue});
                        Navigator.pop(context);
                        _showSuccessSnackBar('Horario actualizado correctamente');
                      } catch (e) {
                        _showErrorSnackBar('Error: $e');
                      }
                    }
                  : null,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Actualizar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Eliminar un horario
  Future<void> _deleteTimeEntry(String comuna, DocumentSnapshot doc) async {
    final time = (doc.data() as Map<String, dynamic>)['time'];
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Eliminar horario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Eliminar el horario $time?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta acción no se puede deshacer',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await doc.reference.delete();
                Navigator.pop(context);
                _showSuccessSnackBar('Horario eliminado correctamente');
              } catch (e) {
                _showErrorSnackBar('Error: $e');
              }
            },
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Eliminar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Maneja las selecciones del menú de usuario
  void _handleUserMenuSelection(String value) {
    switch (value) {
      case 'username':
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Cerrar sesión'),
          ],
        ),
        content: const Text('¿Está seguro de que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () {
              widget.authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;
        
        return Scaffold(
          appBar: _buildAppBar(isDesktop),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFAF8),
                  const Color(0xFFF5F9FF),
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab de Aysén
                isDesktop
                    ? DesktopScheduleLayout(
                        comuna: 'aysen',
                        comunaDisplayName: 'Aysén',
                        destinoDisplayName: 'Coyhaique',
                        isEditing: _isEditing,
                        streamBuilder: _timesDocsStream,
                        onAdd: _addTimeEntry,
                        onEdit: _editTimeEntry,
                        onDelete: _deleteTimeEntry,
                      )
                    : MobileScheduleLayout(
                        comuna: 'aysen',
                        comunaDisplayName: 'Aysén',
                        destinoDisplayName: 'Coyhaique',
                        isEditing: _isEditing,
                        streamBuilder: _timesDocsStream,
                        onAdd: _addTimeEntry,
                        onEdit: _editTimeEntry,
                        onDelete: _deleteTimeEntry,
                      ),

                // Tab de Coyhaique
                isDesktop
                    ? DesktopScheduleLayout(
                        comuna: 'coyhaique',
                        comunaDisplayName: 'Coyhaique',
                        destinoDisplayName: 'Aysén',
                        isEditing: _isEditing,
                        streamBuilder: _timesDocsStream,
                        onAdd: _addTimeEntry,
                        onEdit: _editTimeEntry,
                        onDelete: _deleteTimeEntry,
                      )
                    : MobileScheduleLayout(
                        comuna: 'coyhaique',
                        comunaDisplayName: 'Coyhaique',
                        destinoDisplayName: 'Aysén',
                        isEditing: _isEditing,
                        streamBuilder: _timesDocsStream,
                        onAdd: _addTimeEntry,
                        onEdit: _editTimeEntry,
                        onDelete: _deleteTimeEntry,
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Horarios',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Panel Admin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Aysén'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Coyhaique'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Indicador de modo edición
        if (_isEditing)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 16, color: AppColors.warning),
                SizedBox(width: 6),
                Text(
                  'Editando',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        
        // Botón de edición
        Tooltip(
          message: _isEditing ? 'Guardar cambios' : 'Editar horarios',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          _isEditing ? Icons.edit_rounded : Icons.check_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(_isEditing
                            ? 'Modo edición activado'
                            : 'Cambios guardados'),
                      ],
                    ),
                    backgroundColor: _isEditing ? AppColors.warning : AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _isEditing
                      ? AppColors.success
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        
        // Menú de usuario
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          tooltip: 'Menú de usuario',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          offset: const Offset(0, 50),
          onSelected: _handleUserMenuSelection,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'username',
              enabled: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (widget.authService.currentUser?['username'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.authService.currentUser?['username'] ?? 'Usuario',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Administrador',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            _buildMenuItem('change_username', Icons.badge_outlined, 'Cambiar usuario', AppColors.secondary),
            _buildMenuItem('change_password', Icons.lock_outline_rounded, 'Cambiar contraseña', AppColors.secondary),
            const PopupMenuDivider(),
            _buildMenuItem('add_user', Icons.person_add_outlined, 'Agregar usuario', AppColors.success),
            _buildMenuItem('view_users', Icons.group_outlined, 'Ver usuarios', AppColors.secondary),
            const PopupMenuDivider(),
            _buildMenuItem('logout', Icons.logout_rounded, 'Cerrar sesión', AppColors.error),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
