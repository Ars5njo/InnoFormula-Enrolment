import 'package:flutter/material.dart';

import '../domain/leaderboard.dart';
import '../domain/meeting_repository.dart';
import 'app.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.repository});
  final MeetingRepository repository;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<Leaderboard> _leaderboard;

  @override
  void initState() {
    super.initState();
    _leaderboard = _load();
  }

  Future<Leaderboard> _load() async =>
      Leaderboard(await widget.repository.loadMeetings());

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SelectionArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Masthead(),
                  const SizedBox(height: 44),
                  const _Hero(),
                  const SizedBox(height: 36),
                  FutureBuilder<Leaderboard>(
                    future: _leaderboard,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const _StatePanel(
                          icon: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          title: 'Собираем стартовую решётку',
                          description: 'Загружаем встречи и считаем посещения…',
                        );
                      }
                      if (snapshot.hasError) {
                        return _StatePanel(
                          icon: const Icon(
                            Icons.flag_outlined,
                            color: accent,
                            size: 32,
                          ),
                          title: 'Красный флаг',
                          description: 'Не удалось загрузить все встречи.\nПопробуйте ещё раз чуть позже.',
                          action: FilledButton.icon(
                            onPressed: () => setState(() {
                              _leaderboard = _load();
                            }),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Повторить загрузку'),
                          ),
                        );
                      }
                      final board = snapshot.requireData;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Stats(board: board),
                          const SizedBox(height: 38),
                          _TableHeading(latestMeeting: board.latestMeeting),
                          const SizedBox(height: 18),
                          if (board.entries.isEmpty)
                            const _StatePanel(
                              icon: Icon(
                                Icons.sports_score,
                                color: accent,
                                size: 36,
                              ),
                              title: 'Всё начинается с первой встречи',
                              description: 'Пока здесь нет участников.\nПосле первой встречи появятся первые позиции.',
                            )
                          else
                            _TimingTable(board: board),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 15, color: muted),
                      Text(
                        'Одна встреча — одно посещение.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                      Text(
                        'Равный результат — равное место.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: divider)),
                    ),
                    child: const Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        Text(
                          'INNOFORMULA CLUB',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1.8,
                          ),
                        ),
                        Text(
                          'Увидимся на следующей встрече.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: divider)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 32,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: const Text(
            'IF',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Text(
            'INNOFORMULA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 600) ...[
          const Spacer(),
          const Text(
            'КЛУБ  /  ТАБЛИЦА ПОСЕЩАЕМОСТИ',
            style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.6),
          ),
        ],
      ],
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth > 680;
      return Stack(
        children: [
          if (wide)
            const Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 290,
              child: ExcludeSemantics(
                child: CustomPaint(painter: _TrackPainter()),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Divider(color: accent, thickness: 3),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'КАЖДАЯ ВСТРЕЧА СЧИТАЕТСЯ',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Встречаемся.\nПоднимаемся выше.',
                style: TextStyle(
                  fontSize: wide ? 52 : 34,
                  height: 1.08,
                  letterSpacing: -1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Посещаемость за всё время',
                style: TextStyle(fontSize: 16, color: muted),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 20)
      ..lineTo(112, 20)
      ..quadraticBezierTo(65, 20, 65, 67)
      ..lineTo(65, 95)
      ..quadraticBezierTo(65, 132, 105, 132)
      ..lineTo(190, 132)
      ..quadraticBezierTo(224, 132, 224, 163)
      ..quadraticBezierTo(224, 195, 190, 195)
      ..lineTo(0, 195);
    canvas.drawPath(
      path,
      Paint()
        ..color = divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 36,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF232429)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      const Offset(20, 180),
      const Offset(20, 210),
      Paint()
        ..color = accent
        ..strokeWidth = 4,
    );
    canvas.drawCircle(const Offset(150, 20), 5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) => false;
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

class _Stats extends StatelessWidget {
  const _Stats({required this.board});
  final Leaderboard board;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: panel,
      border: Border.all(color: divider),
      borderRadius: BorderRadius.circular(8),
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              value: '${board.meetings.length}',
              label: 'Проведено встреч',
              index: '01',
            ),
          ),
          const VerticalDivider(width: 1, color: divider),
          Expanded(
            child: _Stat(
              value: '${board.entries.length}',
              label: 'Участников клуба',
              index: '02',
            ),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.index});
  final String value;
  final String label;
  final String index;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 18 : 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 40,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(
              index,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    ),
  );
}

class _TableHeading extends StatelessWidget {
  const _TableHeading({required this.latestMeeting});
  final DateTime? latestMeeting;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 16,
    runSpacing: 12,
    children: [
      const Text(
        'ОБЩИЙ ЗАЧЁТ',
        style: TextStyle(
          fontSize: 15,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        latestMeeting == null
            ? 'В ожидании первой встречи'
            : 'Последняя встреча  ·  ${_date(latestMeeting!)}',
        style: const TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
}

class _TimingTable extends StatelessWidget {
  const _TimingTable({required this.board});
  final Leaderboard board;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      final positionWidth = compact ? 48.0 : 88.0;
      final countWidth = compact ? 78.0 : 130.0;
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: divider),
        ),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF202126),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 26,
                vertical: 16,
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: muted,
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
                child: Row(
                  children: [
                    SizedBox(width: positionWidth, child: const Text('МЕСТО')),
                    const Expanded(child: Text('УЧАСТНИК')),
                    SizedBox(
                      width: countWidth,
                      child: const Text(
                        'ПОСЕЩЕНИЯ',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final entry in board.entries)
              _TimingRow(
                entry: entry,
                positionWidth: positionWidth,
                countWidth: countWidth,
                compact: compact,
                maximum: board.entries.first.attendance,
              ),
          ],
        ),
      );
    },
  );
}

class _TimingRow extends StatelessWidget {
  const _TimingRow({
    required this.entry,
    required this.positionWidth,
    required this.countWidth,
    required this.compact,
    required this.maximum,
  });
  final LeaderboardEntry entry;
  final double positionWidth;
  final double countWidth;
  final bool compact;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    final podiumColor = switch (entry.rank) {
      1 => const Color(0xFFF1C76B),
      2 => const Color(0xFFC6CFDC),
      3 => const Color(0xFFD5A388),
      _ => muted,
    };
    return Semantics(
      label:
          'Место ${entry.rank}, ${entry.participant}, посещений: ${entry.attendance}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: entry.rank == 1 ? const Color(0xFF24221D) : panel,
          border: const Border(top: BorderSide(color: divider)),
        ),
        child: Stack(
          children: [
            if (entry.rank <= 3)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: podiumColor),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 26,
                vertical: 21,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: positionWidth,
                    child: Text(
                      entry.rank.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: podiumColor,
                        fontSize: compact ? 23 : 30,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.participant.split('').join('\u200b'),
                      key: ValueKey('participant-${entry.participant}'),
                      style: TextStyle(
                        fontSize: compact ? 14 : 17,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: countWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.attendance}',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: compact ? 40 : 68,
                          child: LinearProgressIndicator(
                            value: entry.attendance / maximum,
                            minHeight: 2,
                            color: entry.rank <= 3 ? podiumColor : accent,
                            backgroundColor: divider,
                          ),
                        ),
                      ],
                    ),
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

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  final Widget icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: divider),
    ),
    child: Column(
      children: [
        icon,
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: muted, height: 1.6),
        ),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}
