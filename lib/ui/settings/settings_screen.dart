import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scope.dart';
import '../../backup/backup_service.dart';
import '../common/adaptive.dart';
import '../common/confirm_dialog.dart';
import '../common/format.dart';
import '../common/korean_text.dart';
import '../share/sent_links_screen.dart';
import 'how_to_screen.dart';

const privacyPolicyUrl = 'https://tacowasabii.vercel.app/monologue/privacy';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  /// 연습 기록을 백업에 넣을지 묻는다. 크기가 커서 기본은 넣지 않는다. 취소하면 null.
  Future<bool?> _askIncludeMedia(int mediaBytes) {
    var include = false;
    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('백업 내보내기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(keepWords('대본과 원본 사진은 항상 들어가요.')),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: include,
                onChanged: (v) => setDialogState(() => include = v ?? false),
                title: const Text('녹음·영상도 넣기'),
                subtitle: Text(keepWords('약 ${formatBytes(mediaBytes)} · 파일이 커서 만들고 옮기는 데 오래 걸릴 수 있어요')),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, include), child: const Text('내보내기')),
          ],
        ),
      ),
    );
  }

  /// [anchor]는 누른 줄의 context. iPad에서 공유 시트를 그 줄 옆에 띄운다.
  Future<void> _export(BuildContext anchor) async {
    final services = AppScope.of(context);
    final mediaBytes = await services.repo.mediaSizeBytes();
    if (!mounted) return;
    var includeMedia = false;
    if (mediaBytes > 0) {
      final choice = await _askIncludeMedia(mediaBytes);
      if (choice == null || !mounted) return;
      includeMedia = choice;
    }
    setState(() => _busy = true);
    try {
      final String path;
      try {
        path = (await services.backup.export(await getTemporaryDirectory(), includeMedia: includeMedia)).path;
      } catch (_) {
        if (mounted) _snack('백업 파일을 만들지 못했어요.');
        return;
      }
      if (!anchor.mounted) return;
      // 파일을 만드는 동안 창 크기가 바뀌었을 수 있어서 띄우기 직전에 위치를 잰다
      final box = anchor.findRenderObject() as RenderBox?;
      try {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(path, mimeType: 'application/zip')],
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ));
      } catch (_) {
        if (mounted) _snack('공유 화면을 열지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final backup = AppScope.of(context).backup;
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['zip']);
    if (file == null || !mounted) return;
    // 백업이 수 GB일 수 있어서 내용을 메모리에 올리지 않고 경로로 넘긴다
    final path = file.path;
    if (path == null) {
      _snack('이 위치의 파일은 가져올 수 없어요. 파일 앱에 저장한 뒤 다시 골라 주세요.');
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: '백업에서 복원할까요?',
      message: '백업의 대본을 지금 목록에 더해요. 기존 대본은 그대로 남아요.',
      confirmLabel: '가져오기',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final count = await backup.restore(path);
      if (mounted) _snack('대본 $count개를 가져왔어요');
    } on BackupFormatException {
      if (mounted) _snack('백업 파일이 아니거나 손상됐어요');
    } catch (_) {
      if (mounted) _snack('가져오지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = AppScope.of(context).settings;
    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
          ),
        );
    const divider = Divider(indent: 72);
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 0, 20, 40)),
        children: [
          section('화면'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(11)),
                        child: Icon(Icons.contrast_rounded, size: 20, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 16),
                      Text('화면 모드', style: theme.listTileTheme.titleTextStyle),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListenableBuilder(
                    listenable: settings,
                    builder: (context, _) => SegmentedButton<ThemeMode>(
                      expandedInsets: EdgeInsets.zero,
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('기기 설정')),
                        ButtonSegment(value: ThemeMode.light, label: Text('밝게')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('어둡게')),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (v) => settings.setThemeMode(v.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          section('도움말'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: _SettingTile(
              icon: Icons.menu_book_outlined,
              title: '사용 방법',
              subtitle: '사진 보관, 문단 고르기, 백업 같은 기능 안내',
              trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HowToScreen())),
            ),
          ),
          section('백업'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Builder(
                  builder: (tileContext) => _SettingTile(
                    icon: Icons.ios_share_rounded,
                    title: '백업 내보내기',
                    subtitle: '대본과 원본 사진을 파일 하나로 저장해요',
                    enabled: !_busy,
                    onTap: () => _export(tileContext),
                  ),
                ),
                divider,
                _SettingTile(
                  icon: Icons.settings_backup_restore_rounded,
                  title: '백업에서 복원',
                  subtitle: '내보낸 백업 파일을 가져와요',
                  enabled: !_busy,
                  onTap: _restore,
                ),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
          section('공유'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: _SettingTile(
              icon: Icons.link_rounded,
              title: '보낸 링크',
              subtitle: '7일 동안 링크를 복사하거나 지울 수 있어요',
              trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SentLinksScreen())),
            ),
          ),
          section('정보'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보처리방침',
                  trailing: Icon(Icons.open_in_new_rounded, size: 18, color: scheme.onSurfaceVariant),
                  onTap: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
                ),
                divider,
                _SettingTile(
                  icon: Icons.article_outlined,
                  title: '오픈소스 라이선스',
                  trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: '모노로그',
                    applicationVersion: _version,
                  ),
                ),
                divider,
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  title: '버전',
                  trailing: Text(
                    _version ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text('모노로그', style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '사진으로 모으는 독백 대본 노트',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      enabled: enabled,
      onTap: onTap,
    );
  }
}
