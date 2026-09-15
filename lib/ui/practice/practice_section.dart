import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../practice/media_picker.dart';
import '../common/format.dart';
import '../common/korean_text.dart';
import '../design/design.dart';
import 'record_screen.dart';
import 'video_player_screen.dart';

/// 9월 13일 오후 9:30처럼 연습 기록 이름으로 쓰는 날짜·시간.
String takeTitle(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${t.month}월 ${t.day}일 ${t.hour < 12 ? '오전' : '오후'} $hour:${t.minute.toString().padLeft(2, '0')}';
}

enum _AddAction { record, recordVideo, importFile }

enum _FileSource { gallery, files }

/// 대본 화면 아래의 연습 기록(녹음·영상) 구역.
class PracticeSection extends StatefulWidget {
  const PracticeSection({super.key, required this.scriptId, required this.body});

  final int scriptId;

  /// 녹음 화면에 띄울 대본
  final String body;

  @override
  State<PracticeSection> createState() => _PracticeSectionState();
}

class _PracticeSectionState extends State<PracticeSection> {
  Stream<List<MediaItem>>? _takes;
  int? _playingId;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _takes ??= AppScope.of(context).repo.watchMedia(widget.scriptId);
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  /// 아래에서 올라오는 선택 창. 고른 값을 돌려주고, 닫으면 null.
  Future<T?> _choose<T>(String title, List<(T, IconData, String, String?)> options) => showAppSheet<T>(
        context,
        title: title,
        children: (context) => [
          for (final (value, icon, label, detail) in options)
            AppSheetTile(icon: icon, title: label, subtitle: detail, onTap: () => Navigator.pop(context, value)),
        ],
      );

  Future<void> _add() async {
    final action = await _choose<_AddAction>('연습 기록 추가', const [
      (_AddAction.record, Icons.mic_none_rounded, '녹음하기', null),
      (_AddAction.recordVideo, Icons.videocam_outlined, '영상 촬영', null),
      (_AddAction.importFile, Icons.attach_file_rounded, '파일 올리기', '음성·영상 파일'),
    ]);
    if (action == null || !mounted) return;
    final services = AppScope.of(context);
    final repo = services.repo;
    final picker = services.mediaPicker;

    if (action == _AddAction.record) {
      final take = await Navigator.of(context).push<RecordedTake>(
        MaterialPageRoute(builder: (_) => RecordScreen(body: widget.body)),
      );
      if (take == null) return;
      // 녹음 화면의 타이머와 파일의 실제 길이는 수십 ms 어긋나고, 초 단위로 버려 보여 주면
      // 3.99초(0:03)와 4.04초(0:04)처럼 달라 보인다. 재생기와 같은 값을 보여 주도록
      // 파일에서 읽은 길이를 쓰고, 읽지 못할 때만 타이머 값을 쓴다.
      final duration = await picker.audioDuration(services.media.pathOf(take.fileName)) ?? take.duration;
      await repo.addMedia(widget.scriptId, kind: MediaKind.audio, storedFileName: take.fileName, duration: duration);
      return;
    }

    // 폰으로 찍은 영상은 사진첩에, 받거나 저장한 파일은 파일 앱에 있어서 어디서 가져올지 한 번 더 고른다
    var source = _FileSource.gallery;
    if (action == _AddAction.importFile) {
      final chosen = await _choose<_FileSource>('어디서 가져올까요?', const [
        (_FileSource.gallery, Icons.photo_library_outlined, '사진첩', '촬영해 둔 영상'),
        (_FileSource.files, Icons.folder_outlined, '파일', '받거나 저장해 둔 음성·영상 파일'),
      ]);
      if (chosen == null || !mounted) return;
      source = chosen;
    }

    try {
      final picked = await switch ((action, source)) {
        (_AddAction.recordVideo, _) => picker.recordVideo(),
        (_, _FileSource.gallery) => picker.pickFromGallery(),
        (_, _FileSource.files) => picker.pickFromFiles(),
      };
      if (picked == null || !mounted) return;
      // 영상은 복사에 시간이 걸릴 수 있어서 진행 중임을 보여 준다
      setState(() => _busy = true);
      await repo.importMedia(widget.scriptId, kind: picked.kind, sourcePath: picked.path, duration: picked.duration);
    } on UnsupportedMediaFile {
      if (mounted) _snack('음성이나 영상 파일만 올릴 수 있어요.');
    } on PlatformException catch (e) {
      if (mounted) {
        _snack(e.code.contains('denied') ? '카메라·사진 권한이 필요해요. 설정 앱에서 허용해 주세요.' : '가져오지 못했어요. 다시 시도해 주세요.');
      }
    } catch (_) {
      if (mounted) _snack('가져오지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(MediaItem take) {
    if (take.kind == MediaKind.video) {
      final path = AppScope.of(context).media.pathOf(take.fileName);
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => VideoPlayerScreen(path: path, title: takeTitle(take.createdAt))),
      );
    } else {
      setState(() => _playingId = _playingId == take.id ? null : take.id);
    }
  }

  Future<void> _delete(MediaItem take) async {
    final repo = AppScope.of(context).repo;
    final label = take.kind == MediaKind.audio ? '음성' : '영상';
    final ok = await showConfirmDialog(
      context,
      title: '$label 기록을 지울까요?',
      message: '${takeTitle(take.createdAt)}에 남긴 파일도 함께 지워져요.',
      confirmLabel: '지우기',
      destructive: true,
    );
    if (!ok) return;
    if (_playingId == take.id && mounted) setState(() => _playingId = null);
    await repo.deleteMedia(take.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = AppScope.of(context).media;
    return StreamBuilder<List<MediaItem>>(
      stream: _takes,
      builder: (context, snap) {
        final takes = snap.data ?? const <MediaItem>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('연습 기록', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (takes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      '${takes.length}',
                      style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _busy ? null : _add,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('추가'),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (takes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  keepWords('대본을 보면서 녹음하거나 영상을 찍어 연습을 남겨 보세요.'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.6),
                ),
              )
            else
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, take) in takes.indexed) ...[
                      if (i > 0) const Divider(height: 1, indent: 70),
                      _TakeTile(
                        take: take,
                        playing: _playingId == take.id,
                        onTap: () => _open(take),
                        onLongPress: () => _delete(take),
                      ),
                      if (_playingId == take.id) _AudioTakePlayer(key: ValueKey(take.id), path: media.pathOf(take.fileName)),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TakeTile extends StatelessWidget {
  const _TakeTile({required this.take, required this.playing, required this.onTap, required this.onLongPress});

  final MediaItem take;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final audio = take.kind == MediaKind.audio;
    final ms = take.durationMs;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(11)),
        child: Icon(audio ? Icons.mic_none_rounded : Icons.videocam_outlined, size: 20, color: scheme.onPrimaryContainer),
      ),
      title: Text(takeTitle(take.createdAt)),
      subtitle: Text([audio ? '음성' : '영상', if (ms != null) formatDuration(Duration(milliseconds: ms))].join(' · ')),
      trailing: Icon(
        audio ? (playing ? Icons.expand_less_rounded : Icons.play_arrow_rounded) : Icons.play_circle_outline_rounded,
        color: scheme.primary,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// 음성 줄을 누르면 그 아래에 펼쳐지는 재생기. 펼칠 때 만들어 바로 재생한다.
class _AudioTakePlayer extends StatefulWidget {
  const _AudioTakePlayer({super.key, required this.path});

  final String path;

  @override
  State<_AudioTakePlayer> createState() => _AudioTakePlayerState();
}

class _AudioTakePlayerState extends State<_AudioTakePlayer> {
  final _player = AudioPlayer();
  Duration _duration = Duration.zero;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _player.setFilePath(widget.path);
      if (!mounted) return;
      setState(() => _duration = d ?? Duration.zero);
      _player.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(70, 0, 16, 12),
        child: Text('이 파일은 재생할 수 없어요', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snap) {
              final state = snap.data;
              final completed = state?.processingState == ProcessingState.completed;
              final playing = (state?.playing ?? false) && !completed;
              return IconButton(
                tooltip: playing ? '일시정지' : '재생',
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                onPressed: () async {
                  if (playing) {
                    await _player.pause();
                    return;
                  }
                  if (completed) await _player.seek(Duration.zero);
                  _player.play();
                },
              );
            },
          ),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snap) {
                final max = _duration.inMilliseconds.toDouble();
                final position = (snap.data ?? Duration.zero).inMilliseconds.toDouble().clamp(0.0, max);
                return Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: max > 0 ? position : 0,
                        max: max > 0 ? max : 1,
                        onChanged: max > 0 ? (v) => _player.seek(Duration(milliseconds: v.round())) : null,
                      ),
                    ),
                    Text(
                      '${formatDuration(Duration(milliseconds: position.round()))} / ${formatDuration(_duration)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
