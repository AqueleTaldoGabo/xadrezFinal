import 'package:flutter/material.dart';

import '../service/auth_service.dart';
import 'daily_page.dart';
import 'leaderboards_page.dart';
import 'player_page.dart';
import 'random_page.dart';
import 'records_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().user;
    final displayName = user?.displayName?.trim();
    final greeting = displayName != null && displayName.isNotEmpty
        ? displayName
        : (user?.email ?? 'jogador');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess.com App'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => AuthService().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFF81B64C),
                  child: Icon(Icons.sports_esports,
                      size: 48, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Olá, $greeting',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                _item(context, 'Buscar Jogador', Icons.person_search,
                    const PlayerPage()),
                _item(context, 'Puzzle do Dia', Icons.today, const DailyPage()),
                _item(context, 'Puzzle Aleatório', Icons.casino,
                    const RandomPage()),
                _item(context, 'Ranking Global', Icons.leaderboard,
                    const LeaderboardPage()),
                _item(context, 'Minhas Partidas e Calendário',
                    Icons.calendar_month, const RecordsPage()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF81B64C),
            padding: const EdgeInsets.symmetric(vertical: 17),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => page),
          ),
          icon: Icon(icon),
          label: Text(title),
        ),
      ),
    );
  }
}
