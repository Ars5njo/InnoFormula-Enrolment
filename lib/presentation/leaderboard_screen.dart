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
                  const SizedBox(height: 34),
                  const _Hero(),
                  const SizedBox(height: 28),
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
                          const SizedBox(height: 40),
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 48),
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
                            fontFamily: 'RussoOne',
                            fontSize: 11,
                            letterSpacing: 1.3,
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
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: divider)),
    ),
    child: Row(
      children: [
        Image.asset(
          'assets/branding/club-mark.png',
          width: 88,
          height: 59,
          fit: BoxFit.contain,
          semanticLabel: 'Логотип InnoFormula — три болида',
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'INNOFORMULA',
            style: TextStyle(
              fontFamily: 'RussoOne',
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 780) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(color: divider),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14),
              ),
            ),
            child: const Text(
              'ВСТРЕЧИ. ЛЮДИ. ФОРМУЛА.',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
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
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF181822),
          border: Border.all(color: divider),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(44),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: wide ? -35 : -150,
              top: 0,
              bottom: 0,
              width: 410,
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _TrackPainter(opacity: wide ? 1 : 0.35),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: ColoredBox(color: accent),
            ),
            Padding(
              padding: EdgeInsets.all(wide ? 36 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 7, height: 7, color: accent),
                      const SizedBox(width: 9),
                      const Flexible(
                        child: Text(
                          'КАЖДАЯ ВСТРЕЧА СЧИТАЕТСЯ',
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'КАЖДАЯ ВСТРЕЧА',
                    style: displayStyle.copyWith(
                      fontSize: wide ? 43 : 27,
                      height: 1.12,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'В ЗАЧЁТ.',
                    style: displayStyle.copyWith(
                      fontSize: wide ? 64 : 44,
                      color: accent,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Посещаемость за всё время',
                    style: TextStyle(fontSize: 15, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// An evolution of the site's track decoration: repeated racing-line geometry.
class _TrackPainter extends CustomPainter {
  const _TrackPainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 7; i++) {
      final offset = i * 13.0;
      final path = Path()
        ..moveTo(size.width + 30, size.height * 0.13 + offset)
        ..lineTo(size.width * 0.68 + offset, size.height * 0.13 + offset)
        ..quadraticBezierTo(
          size.width * 0.60 + offset,
          size.height * 0.13 + offset,
          size.width * 0.55 + offset,
          size.height * 0.23 + offset,
        )
        ..lineTo(size.width * 0.10 + offset, size.height + 20);
      canvas.drawPath(
        path,
        Paint()
          ..color = (i < 3 ? accent : racingPurple).withValues(
            alpha: (0.28 - i * 0.02) * opacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) =>
      opacity != oldDelegate.opacity;
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
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(6),
      ),
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              value: '${board.meetings.length}',
              label: 'Проведено встреч',
              index: '01',
              color: accent,
            ),
          ),
          const VerticalDivider(width: 1, color: divider),
          Expanded(
            child: _Stat(
              value: '${board.entries.length}',
              label: 'Участников клуба',
              index: '02',
              color: electricBlue,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.index,
    required this.color,
  });
  final String value;
  final String label;
  final String index;
  final Color color;

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
                style: displayStyle.copyWith(
                  fontSize: 40,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
        const SizedBox(height: 13),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 3, height: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
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
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 4, height: 21, color: accent),
          const SizedBox(width: 10),
          Text(
            'ОБЩИЙ ЗАЧЁТ',
            style: displayStyle.copyWith(fontSize: 18, letterSpacing: 0.4),
          ),
        ],
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
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(color: divider),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF252532),
                border: Border(top: BorderSide(color: accent, width: 3)),
              ),
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
            for (var index = 0; index < board.entries.length; index++)
              _TimingRow(
                entry: board.entries[index],
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
          gradient: entry.rank <= 3
              ? LinearGradient(
                  colors: [podiumColor.withValues(alpha: 0.06), panel],
                  stops: const [0, 0.4],
                )
              : null,
          color: entry.rank <= 3 ? null : panel,
          border: const Border(top: BorderSide(color: divider)),
        ),
        child: Stack(
          children: [
            if (entry.rank <= 3)
              Positioned(
                left: 0,
                top: 18,
                bottom: 18,
                width: 3,
                child: ColoredBox(color: podiumColor),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 26,
                vertical: 19,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: positionWidth,
                    child: Text(
                      entry.rank.toString().padLeft(2, '0'),
                      style: displayStyle.copyWith(
                        color: podiumColor,
                        fontSize: compact ? 22 : 28,
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
                        fontSize: compact ? 14 : 16,
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
                          style: displayStyle.copyWith(
                            fontSize: 25,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: compact ? 34 : 62,
                          child: LinearProgressIndicator(
                            value: entry.attendance / maximum,
                            minHeight: 2,
                            color: entry.rank <= 3 ? podiumColor : electricBlue,
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
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(6),
      ),
      border: Border.all(color: divider),
    ),
    child: Column(
      children: [
        icon,
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: displayStyle.copyWith(fontSize: 20, height: 1.4),
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
