import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with SingleTickerProviderStateMixin {
  late final FirebaseFirestore _firestore;
  bool _isEditing = false;
  late TabController _tabController;

  // Constantes para uso a lo largo del widget
  final Color _aysenColor = Colors.blue.shade700;
  final Color _coyhaiqueCplor = Colors.green.shade700;

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

  /// Formatea el texto para asegurar formato HH:MM
  String _formatTimeInput(String value) {
    // Elimina todos los caracteres que no sean dígitos
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Límite a 4 dígitos
    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    // Formatea como HH:MM
    if (digitsOnly.length >= 3) {
      return '${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2)}';
    } else if (digitsOnly.length == 2) {
      return '$digitsOnly:';
    }

    return digitsOnly;
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
            style: TextStyle(color: comuna == 'aysen' ? _aysenColor : _coyhaiqueCplor),
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
                  // Formateador personalizado
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final formatted = _formatTimeInput(newValue.text);
                    return TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }),
                  // Limita a 5 caracteres (HH:MM)
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
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
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
                backgroundColor: comuna == 'aysen' ? _aysenColor : _coyhaiqueCplor,
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
            style: TextStyle(color: comuna == 'aysen' ? _aysenColor : _coyhaiqueCplor),
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
                  // Formateador personalizado
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final formatted = _formatTimeInput(newValue.text);
                    return TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }),
                  // Limita a 5 caracteres (HH:MM)
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
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
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
                backgroundColor: comuna == 'aysen' ? _aysenColor : _coyhaiqueCplor,
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
          style: TextStyle(color: Colors.red.shade700),
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
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                await doc.reference.delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Horario eliminado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
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
          return _buildEmptyCard(title, comuna, dayType, headerColor);
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
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
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
                            color: headerColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: headerColor,
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
                              icon: Icon(Icons.edit, color: headerColor),
                              onPressed: () => _editTimeEntry(comuna, dayType, doc),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
            const CircularProgressIndicator(),
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
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
            const SizedBox(height: 12),
            Text(
              'Error cargando "$title"',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
            Text(
              error,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar cuando no hay horarios
  Widget _buildEmptyCard(String title, String comuna, String dayType, Color headerColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: headerColor, size: 48),
            const SizedBox(height: 12),
            Text(
              'No hay horarios disponibles para "$title"',
              style: TextStyle(color: headerColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _addTimeEntry(comuna, dayType),
                icon: const Icon(Icons.add),
                label: const Text('Agregar horario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: headerColor,
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
        backgroundColor: Colors.blue.shade800,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
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
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
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
                    color: _aysenColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _aysenColor,
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
                  _buildScheduleCard('Lunes a Viernes', 'aysen', 'lunesViernes', _aysenColor),
                  _buildScheduleCard('Sábados', 'aysen', 'sabados', _aysenColor),
                  _buildScheduleCard('Domingos y Feriados', 'aysen', 'domingosFeriados', _aysenColor),
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
                    color: _coyhaiqueCplor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _coyhaiqueCplor,
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
                  _buildScheduleCard('Lunes a Viernes', 'coyhaique', 'lunesViernes', _coyhaiqueCplor),
                  _buildScheduleCard('Sábados', 'coyhaique', 'sabados', _coyhaiqueCplor),
                  _buildScheduleCard('Domingos y Feriados', 'coyhaique', 'domingosFeriados', _coyhaiqueCplor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}