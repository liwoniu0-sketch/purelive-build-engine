import 'package:pure_live/core/index.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/markdown_block.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '⚡ 已就绪 Cloudflare 国内极速免翻墙更新通道',
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
        FilledButton(
          key: const ValueKey('new-version-update'),
          onPressed: () {
            Navigator.pop(context);
            final callback = onUpdate;
            if (callback != null) {
              callback();
            } else {
              Get.toNamed(RoutePath.kVersionPage);
            }
          },
          child: Text(i18n("update")),
        ),
      ],
    );
  }
}
