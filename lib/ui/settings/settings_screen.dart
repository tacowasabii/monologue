import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scope.dart';
import '../../backup/backup_service.dart';

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

  Future<void> _export() async {
    final backup = AppScope.of(context).backup;
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _busy = true);
    try {
      final file = await backup.export(await getTemporaryDirectory());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/zip')],
        // iPad는 공유 시트 위치가 필요하다
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (_) {
      if (mounted) _snack('백업 파일을 만들지 못했어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final backup = AppScope.of(context).backup;
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['zip']);
    if (file == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업에서 복원'),
        content: const Text('백업의 대본을 지금 목록에 추가할까요? 기존 대본은 그대로 남아요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('가져오기')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final count = await backup.restore(await file.readAsBytes());
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
    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          section('백업'),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('백업 내보내기'),
            subtitle: const Text('대본과 원본 사진을 파일 하나로 저장해요'),
            enabled: !_busy,
            onTap: _export,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('백업에서 복원'),
            subtitle: const Text('내보낸 백업 파일을 가져와요'),
            enabled: !_busy,
            onTap: _restore,
          ),
          if (_busy) const LinearProgressIndicator(),
          const Divider(height: 32),
          section('정보'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보처리방침'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('버전'),
            trailing: Text(_version ?? ''),
          ),
        ],
      ),
    );
  }
}
