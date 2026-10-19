import 'dart:io';
import 'package:pure_live/core/index.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:pure_live/features/version/app_update_flow.dart';

class NoNewVersionDialog extends StatelessWidget {
  const NoNewVersionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(i18n("check_update")),
      content: Text(i18n("no_new_version_info")),
      actions: <Widget>[
        TextButton(
          child: Text(i18n("confirm")),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class NewVersionDialog extends StatelessWidget {
  const NewVersionDialog({super.key, this.onOpenProject, this.onUpdate});

  final VoidCallback? onOpenProject;
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final config = Get.isDarkMode ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    return AlertDialog(
      key: const ValueKey('new-version-dialog'),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      title: Text(i18n("check_update")),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.swap_calls_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '支持双通道自由更新：国内直连请选【⚡ 极速源】，开启VPN请选【🌐 官方源】',
                    style: AppTextStyles.t11.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            key: const ValueKey('new-version-open-project'),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            onPressed: () {
              Navigator.pop(context);
              final callback = onOpenProject;
              if (callback != null) {
                callback();
              } else {
                launchUrl(Uri.parse(VersionUtil.projectUrl), mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(i18n('open_source_free'), style: AppTextStyles.t15),
          ),
          MarkdownBlock(data: VersionUtil.latestUpdateLog, config: config),
          const SizedBox(height: 10),
        ],
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: <Widget>[
        TextButton(
          key: const ValueKey('new-version-cancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(i18n("cancel")),
        ),
        TextButton(
          key: const ValueKey('new-version-more'),
          onPressed: () {
            Navigator.pop(context);
            Get.toNamed(RoutePath.kVersionPage);
          },
          child: const Text("更多版本"),
        ),
        OutlinedButton.icon(
          key: const ValueKey('new-version-update-official'),
          icon: const Icon(Icons.public_rounded, size: 16),
          label: const Text("🌐 官方源 (需VPN)"),
          onPressed: () {
            Navigator.pop(context);
            if (Platform.isAndroid) {
              final targetUrl = VersionUtil.getOfficialApkUrl();
              downloadAndInstallApk(targetUrl);
            } else {
              Get.toNamed(RoutePath.kVersionPage);
            }
          },
        ),
        FilledButton.icon(
          key: const ValueKey('new-version-update-cf'),
          icon: const Icon(Icons.bolt_rounded, size: 16),
          label: const Text("⚡ 国内极速更新"),
          onPressed: () {
            Navigator.pop(context);
            final callback = onUpdate;
            if (callback != null) {
              callback();
            } else {
              if (Platform.isAndroid) {
                final targetUrl = VersionUtil.getRecommendedApkUrl();
                downloadAndInstallApk(targetUrl);
              } else {
                Get.toNamed(RoutePath.kVersionPage);
              }
            }
          },
        ),
      ],
    );
  }
}
