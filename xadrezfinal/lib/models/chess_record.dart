class ChessRecord {
  final String id;
  final String opponent;
  final String result;
  final String notes;
  final DateTime date;
  final double? latitude;
  final double? longitude;
  final String? imagePath;
  final bool synced;

  const ChessRecord({
    required this.id,
    required this.opponent,
    required this.result,
    required this.notes,
    required this.date,
    this.latitude,
    this.longitude,
    this.imagePath,
    this.synced = false,
  });

  ChessRecord copyWith({bool? synced, String? imagePath}) => ChessRecord(
        id: id,
        opponent: opponent,
        result: result,
        notes: notes,
        date: date,
        latitude: latitude,
        longitude: longitude,
        imagePath: imagePath ?? this.imagePath,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'opponent': opponent,
        'result': result,
        'notes': notes,
        'date': date.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'imagePath': imagePath,
        'synced': synced ? 1 : 0,
      };

  factory ChessRecord.fromMap(Map<String, dynamic> map) => ChessRecord(
        id: map['id'] as String,
        opponent: map['opponent'] as String,
        result: map['result'] as String,
        notes: (map['notes'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        imagePath: map['imagePath'] as String?,
        synced: map['synced'] == 1,
      );

  factory ChessRecord.fromCloud(String id, Map<String, dynamic> map) {
    final rawDate = map['date'];
    return ChessRecord(
      id: id,
      opponent: (map['opponent'] as String?) ?? 'Adversário',
      result: (map['result'] as String?) ?? 'Empate',
      notes: (map['notes'] as String?) ?? '',
      date: rawDate is String
          ? DateTime.tryParse(rawDate) ?? DateTime.now()
          : rawDate is DateTime
              ? rawDate
              : DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      // A imagem fica no dispositivo; o caminho é recuperado do SQLite.
      imagePath: null,
      synced: true,
    );
  }

  Map<String, dynamic> toCloud() => {
        'id': id,
        'opponent': opponent,
        'result': result,
        'notes': notes,
        'date': date.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': DateTime.now().toIso8601String(),
      };
}
