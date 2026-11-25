import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chess_record.dart';
import 'local_db.dart';

/// Offline-first: SQLite guarda somente alterações ainda não confirmadas.
/// Os registros já enviados são lidos do Firestore (incluindo cache offline).
class RecordService {
  RecordService._() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        if (!results.contains(ConnectivityResult.none)) {
          sync().catchError((_) {});
        }
      },
    );
  }

  static final RecordService _instance = RecordService._();
  factory RecordService() => _instance;

  final LocalDb _local = LocalDb.instance;
  final FirebaseFirestore _cloud = FirebaseFirestore.instance;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _syncing = false;
  bool _syncRequested = false;

  Stream<void> get changes => _changes.stream;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _uid;
    if (uid == null) throw StateError('Faça login para acessar suas partidas.');
    return _cloud.collection('users').doc(uid).collection('records');
  }

  Future<List<ChessRecord>> all() async {
    final uid = _uid;
    if (uid == null) return const <ChessRecord>[];

    final Map<String, ChessRecord> combined = {};
    try {
      final snapshot = await _collection.get();
      for (final doc in snapshot.docs) {
        final cloudRecord = ChessRecord.fromCloud(doc.id, doc.data());
        combined[doc.id] = cloudRecord.copyWith(
          imagePath: await _local.mediaPath(uid, doc.id),
        );
      }
    } catch (_) {
      // Quando offline, tenta os documentos que o Firestore já armazenou em cache.
      try {
        final snapshot = await _collection.get(
          const GetOptions(source: Source.cache),
        );
        for (final doc in snapshot.docs) {
          final cloudRecord = ChessRecord.fromCloud(doc.id, doc.data());
        combined[doc.id] = cloudRecord.copyWith(
          imagePath: await _local.mediaPath(uid, doc.id),
        );
        }
      } catch (_) {
        // A primeira abertura offline pode não ter cache ainda.
      }
    }

    for (final record in await _local.all(uid)) {
      combined[record.id] = record;
    }

    final deletedIds = (await _local.deletions(uid)).toSet();
    for (final id in deletedIds) {
      combined.remove(id);
    }

    final records = combined.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<void> save(ChessRecord record) async {
    // Primeiro grava localmente: não perde a alteração se a rede falhar.
    final uid = _uid;
    if (uid == null) throw StateError('Faça login para salvar partidas.');
    await _local.save(uid, record.copyWith(synced: false));
    await sync();
    _changes.add(null);
  }

  Future<void> remove(String id) async {
    // Registra a exclusão antes de remover localmente: será replicada na nuvem.
    final uid = _uid;
    if (uid == null) throw StateError('Faça login para excluir partidas.');
    await _local.delete(uid, id);
    await sync();
    _changes.add(null);
  }

  Future<void> sync() async {
    if (_uid == null) return;
    if (_syncing) {
      _syncRequested = true;
      return;
    }
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    _syncing = true;
    try {
      final uid = _uid!;
      final collection = _collection;
      var changed = false;

      for (final record in await _local.pending(uid)) {
        await collection.doc(record.id).set(record.toCloud());
        await _local.saveMedia(uid, record.id, record.imagePath);
        // Só remove da fila local depois da confirmação do Firestore.
        await _local.removePendingRecord(uid, record.id);
        changed = true;
      }

      for (final id in await _local.deletions(uid)) {
        await collection.doc(id).delete();
        await _local.clearDelete(uid, id);
        await _local.removeMedia(uid, id);
        changed = true;
      }
      if (changed) _changes.add(null);
    } finally {
      _syncing = false;
      if (_syncRequested) {
        _syncRequested = false;
        sync().catchError((_) {});
      }
    }
  }
}
