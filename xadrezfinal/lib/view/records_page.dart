import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/chess_record.dart';
import '../service/record_service.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final RecordService service = RecordService();
  StreamSubscription<void>? _changesSubscription;
  List<ChessRecord> records = [];
  DateTime selected = DateTime.now();
  DateTime focused = DateTime.now();
  CalendarFormat format = CalendarFormat.month;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _changesSubscription = service.changes.listen((_) => refresh());
    refresh();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      await service.sync();
      final result = await service.all();
      if (!mounted) return;
      setState(() {
        records = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar partidas: $e')),
      );
    }
  }

  List<ChessRecord> get dayRecords => records
      .where((record) => isSameDay(record.date, selected))
      .toList();

  Future<void> edit([ChessRecord? old]) async {
    final record = await showDialog<ChessRecord>(
      context: context,
      builder: (_) => RecordEditDialog(old: old, initialDate: selected),
    );
    if (!mounted || record == null) return;
    try {
      await service.save(record);
      await refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partida salva.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar partida: $e')),
      );
    }
  }

  Future<void> showDetails(ChessRecord record) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF262421),
        title: Text('Partida contra ${record.opponent}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resultado: ${record.result}'),
              const SizedBox(height: 8),
              Text('Data: ${record.date.day}/${record.date.month}/${record.date.year}'),
              if (record.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Observações: ${record.notes}'),
              ],
              if (record.latitude != null && record.longitude != null) ...[
                const SizedBox(height: 8),
                Text('Latitude: ${record.latitude}'),
                Text('Longitude: ${record.longitude}'),
              ],
              if (record.imagePath != null && File(record.imagePath!).existsSync()) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(record.imagePath!)),
                ),
              ],
              const SizedBox(height: 8),
              Text(record.synced ? 'Sincronizada com Firebase' : 'Pendente de sincronização'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              edit(record);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteRecord(ChessRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF262421),
        title: const Text('Excluir partida?'),
        content: Text('Deseja excluir a partida contra ${record.opponent}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await service.remove(record.id);
      await refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir partida: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas partidas'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: () async {
              await service.sync();
              await refresh();
            },
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF81B64C),
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<ChessRecord>(
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2100),
                  focusedDay: focused,
                  calendarFormat: format,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mês',
                    CalendarFormat.twoWeeks: '2 semanas',
                    CalendarFormat.week: 'Semana',
                  },
                  selectedDayPredicate: (day) => isSameDay(day, selected),
                  eventLoader: (day) => records
                      .where((record) => isSameDay(record.date, day))
                      .toList(),
                  onFormatChanged: (newFormat) =>
                      setState(() => format = newFormat),
                  onPageChanged: (newFocused) => focused = newFocused,
                  onDaySelected: (newSelected, newFocused) {
                    setState(() {
                      selected = newSelected;
                      focused = newFocused;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Color(0xFF81B64C),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF81B64C),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: dayRecords.isEmpty
                      ? const Center(
                          child: Text('Nenhuma partida nesta data.'),
                        )
                      : ListView.builder(
                          itemCount: dayRecords.length,
                          itemBuilder: (context, index) {
                            final record = dayRecords[index];
                            final hasImage = record.imagePath != null &&
                                File(record.imagePath!).existsSync();
                            return Card(
                              child: ListTile(
                                leading: hasImage
                                    ? CircleAvatar(
                                        backgroundImage: FileImage(
                                          File(record.imagePath!),
                                        ),
                                      )
                                    : const CircleAvatar(
                                        child: Icon(Icons.sports_esports),
                                      ),
                                title: Text(record.opponent),
                                subtitle: Text(
                                  '${record.result} • ${record.date.day}/'
                                  '${record.date.month}/${record.date.year}\n'
                                  '${record.synced ? 'Sincronizada' : 'Pendente de sincronização'}',
                                ),
                                isThreeLine: true,
                                onTap: () => showDetails(record),
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => edit(record),
                                    ),
                                    IconButton(
                                      tooltip: 'Excluir',
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => deleteRecord(record),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class RecordEditDialog extends StatefulWidget {
  final ChessRecord? old;
  final DateTime initialDate;

  const RecordEditDialog({super.key, this.old, required this.initialDate});

  @override
  State<RecordEditDialog> createState() => _RecordEditDialogState();
}

class _RecordEditDialogState extends State<RecordEditDialog> {
  late final TextEditingController opponent;
  late final TextEditingController notes;
  late String result;
  late DateTime date;
  double? latitude;
  double? longitude;
  String? imagePath;
  bool gettingLocation = false;

  @override
  void initState() {
    super.initState();
    opponent = TextEditingController(text: widget.old?.opponent ?? '');
    notes = TextEditingController(text: widget.old?.notes ?? '');
    result = widget.old?.result ?? 'Vitória';
    date = widget.old?.date ?? widget.initialDate;
    latitude = widget.old?.latitude;
    longitude = widget.old?.longitude;
    imagePath = widget.old?.imagePath;
  }

  @override
  void dispose() {
    opponent.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> registerLocation() async {
    setState(() => gettingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Ative o GPS do dispositivo.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => gettingLocation = false);
    }
  }

  Future<void> selectImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (!mounted || picked == null) return;
    setState(() => imagePath = picked.path);
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => date = picked);
  }

  void save() {
    if (opponent.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o adversário.')),
      );
      return;
    }
    Navigator.pop(
      context,
      ChessRecord(
        id: widget.old?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        opponent: opponent.text.trim(),
        result: result,
        notes: notes.text.trim(),
        date: date,
        latitude: latitude,
        longitude: longitude,
        imagePath: imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF262421),
      title: Text(widget.old == null ? 'Nova partida' : 'Editar partida'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: opponent,
              decoration: const InputDecoration(labelText: 'Adversário'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: result,
              decoration: const InputDecoration(labelText: 'Resultado'),
              items: ['Vitória', 'Derrota', 'Empate']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => result = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            TextButton.icon(
              onPressed: gettingLocation ? null : registerLocation,
              icon: const Icon(Icons.location_on),
              label: Text(gettingLocation
                  ? 'Obtendo localização...'
                  : latitude == null
                      ? 'Registrar GPS'
                      : 'GPS: $latitude, $longitude'),
            ),
            TextButton.icon(
              onPressed: selectImage,
              icon: const Icon(Icons.image),
              label: Text(imagePath == null
                  ? 'Selecionar imagem'
                  : 'Imagem selecionada'),
            ),
            TextButton(
              onPressed: selectDate,
              child: Text('Data: ${date.day}/${date.month}/${date.year}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: save, child: const Text('Salvar')),
      ],
    );
  }
}
