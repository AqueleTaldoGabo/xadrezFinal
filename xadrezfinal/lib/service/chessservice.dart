import 'dart:convert';

import 'package:http/http.dart' as http;

class ChessApiService {
  static const _headers = {
    'User-Agent': 'ChessComFlutterStudentApp/1.0 (Flutter)',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> _getMap(String url, String errorMessage) async {
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('$errorMessage (HTTP ${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('A API retornou um formato inesperado.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> getPlayer(String username) {
    final safeUsername = Uri.encodeComponent(username.trim());
    return _getMap(
      'https://api.chess.com/pub/player/$safeUsername',
      'Jogador não encontrado',
    );
  }

  Future<Map<String, dynamic>> getDaily() => _getMap(
        'https://api.chess.com/pub/puzzle',
        'Erro ao carregar puzzle do dia',
      );

  Future<Map<String, dynamic>> getRandom() => _getMap(
        'https://api.chess.com/pub/puzzle/random',
        'Erro ao carregar puzzle aleatório',
      );

  Future<Map<String, dynamic>> getLeaderboards() => _getMap(
        'https://api.chess.com/pub/leaderboards',
        'Erro ao carregar rankings',
      );
}
