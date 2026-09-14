import 'package:flutter/material.dart';

import '../capture/capture_flow.dart';
import 'script_edit_screen.dart';

/// 사진이나 직접 입력으로 새 대본을 만든다. 모음 안에서 시작하면 그 모음을 미리 골라 둔다.
Future<void> addScript(BuildContext context, {int? collectionId}) async {
  final result = await runCapture(context);
  if (result == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<int>(
    builder: (_) => ScriptEditScreen(
      initialBody: result.text,
      newImagePaths: result.imagePaths,
      failedImages: result.failedCount,
      initialCollectionIds: [?collectionId],
    ),
  ));
}
