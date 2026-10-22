import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diario_de_contas/models/expense.dart';
import 'package:diario_de_contas/services/auth_service.dart';
import 'package:diario_de_contas/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class BackupResult {
  const BackupResult({
    required this.total,
    required this.uploaded,
    required this.alreadyPresent,
    required this.conflicts,
    required this.failed,
    this.unauthenticated = false,
  });

  final int total;
  final int uploaded;
  final int alreadyPresent;
  final int conflicts;
  final int failed;
  final bool unauthenticated;

  bool get isComplete => !unauthenticated && conflicts == 0 && failed == 0;

  String get summary {
    if (unauthenticated) return 'Entre com o Google para fazer o backup.';
    if (isComplete) {
      return 'Backup concluído: $uploaded enviado(s) e '
          '$alreadyPresent já existente(s) de $total.';
    }
    return 'Backup parcial: $uploaded enviado(s), '
        '$alreadyPresent já existente(s), $conflicts conflito(s) e '
        '$failed falha(s).';
  }
}

class FirestoreBackupService extends ChangeNotifier {
  FirestoreBackupService({
    required this.authService,
    StorageService? storage,
    FirebaseFirestore? firestore,
  })  : _storage = storage ?? StorageService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService authService;
  final StorageService _storage;
  final FirebaseFirestore _firestore;

  bool _isBusy = false;
  String? _errorMessage;

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  Future<BackupResult> backupLocalExpenses() async {
    final uid = authService.uid;
    if (uid == null || uid.isEmpty) {
      return const BackupResult(
        total: 0,
        uploaded: 0,
        alreadyPresent: 0,
        conflicts: 0,
        failed: 0,
        unauthenticated: true,
      );
    }

    _setBusy(true);
    _errorMessage = null;
    try {
      final expenses = await _storage.readExpenses();
      var uploaded = 0;
      var alreadyPresent = 0;
      var conflicts = 0;
      var failed = 0;

      for (final expense in expenses) {
        try {
          final outcome = await _backupExpense(uid, expense);
          switch (outcome) {
            case _BackupOutcome.uploaded:
              uploaded++;
            case _BackupOutcome.alreadyPresent:
              alreadyPresent++;
            case _BackupOutcome.conflict:
              conflicts++;
          }
        } on FirebaseException catch (error) {
          failed++;
          _errorMessage ??= _firebaseErrorMessage(error);
        } catch (_) {
          failed++;
          _errorMessage ??= 'Não foi possível concluir todo o backup.';
        }
      }

      return BackupResult(
        total: expenses.length,
        uploaded: uploaded,
        alreadyPresent: alreadyPresent,
        conflicts: conflicts,
        failed: failed,
      );
    } on FirebaseException catch (error) {
      _errorMessage = _firebaseErrorMessage(error);
      return const BackupResult(
        total: 0,
        uploaded: 0,
        alreadyPresent: 0,
        conflicts: 0,
        failed: 1,
      );
    } catch (_) {
      _errorMessage = 'Não foi possível ler os lançamentos locais.';
      return const BackupResult(
        total: 0,
        uploaded: 0,
        alreadyPresent: 0,
        conflicts: 0,
        failed: 1,
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<_BackupOutcome> _backupExpense(String uid, Expense expense) async {
    final data = expense.toJson();
    final reference = _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expense.id);

    final outcome =
        await _firestore.runTransaction<_BackupOutcome>((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) {
        final existing = snapshot.data();
        if (existing != null && _sameExpense(existing, data)) {
          return _BackupOutcome.alreadyPresent;
        }
        return _BackupOutcome.conflict;
      }

      transaction.set(reference, data);
      return _BackupOutcome.uploaded;
    });

    if (outcome == _BackupOutcome.uploaded) {
      final verification = await reference.get();
      final verifiedData = verification.data();
      if (!verification.exists ||
          verifiedData == null ||
          !_sameExpense(verifiedData, data)) {
        throw StateError('Falha ao validar o documento enviado.');
      }
    }
    return outcome;
  }

  bool _sameExpense(
    Map<String, dynamic> existing,
    Map<String, dynamic> expected,
  ) {
    if (existing['id'] != expected['id'] ||
        existing['person'] != expected['person'] ||
        existing['account'] != expected['account'] ||
        existing['month'] != expected['month']) {
      return false;
    }

    final existingAmounts = existing['amounts'];
    final expectedAmounts = expected['amounts'];
    if (existingAmounts is! List || expectedAmounts is! List) return false;
    if (existingAmounts.length != expectedAmounts.length) return false;

    for (var index = 0; index < expectedAmounts.length; index++) {
      final existingValue = existingAmounts[index];
      final expectedValue = expectedAmounts[index];
      if (existingValue is! num || expectedValue is! num) return false;
      if (existingValue.toDouble() != expectedValue.toDouble()) return false;
    }
    return true;
  }

  String _firebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'O Firebase recusou o backup por falta de permissão.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Não foi possível conectar ao Firebase.';
      case 'cancelled':
        return 'O backup foi cancelado.';
      default:
        return 'Ocorreu um erro ao fazer o backup no Firebase.';
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}

enum _BackupOutcome { uploaded, alreadyPresent, conflict }
