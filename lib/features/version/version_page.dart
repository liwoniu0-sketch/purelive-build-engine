import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/core/index.dart';
import 'package:pure_live/features/version/app_update_flow.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:pure_live/core/platform/platform_utils.dart';
import 'package:pure_live/features/version/version_controller.dart';

typedef VersionDownloadHandler = Future<void> Function(String url, {String? fileName});

Uri? versionDownloadUri(String rawUrl) => updateDownloadUri(rawUrl);

class VersionPage extends GetView<VersionController> {
  const VersionPage({super.key, this.downloadRelease});

  final VersionDownloadHandler? downloadRelease;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final toolbarHeight = textScale <= 1.5 ? kToolbarHeight : math.min(152.0, 44 + 36 * textScale);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: toolbarHeight,
        title: Text(i18n('version_update'), maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
        }
        if (controller.error.value) {
          return _buildErrorState(context);
        }

        return ListView(
          key: const ValueKey('version-update-scroll'),
          physics: const PureLiveScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(Remix.flashlight_fill, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '国内网络请直接点击【⚡ 极速源 (推荐)】下载，内置 Cloudflare 边缘加速，满速免翻墙。',
                      style: AppTextStyles.t12.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (PlatformUtils.isAndroid) ...[
              _buildPlatformCard(
                context,
                title: "Android",
                subtitle: i18n("android_desc"),
                icon: Remix.android_line,
                children: [
                  _buildDownloadSection(context, title: i18n("arch_arm64"), urls: controller.androidArm64Url.value),
                  const SizedBox(height: 16),
                  _buildDownloadSection(
                    context,
                    title: i18n("arch_arm32"),
                    urls: controller.androidArmeabiV7aUrl.value,
                  ),
                  const SizedBox(height: 16),
                  _buildDownloadSection(context, title: i18n("arch_x86_64"), urls: controller.androidX8664Url.value),
                ],
              ),
              const SizedBox(height: 24),
            ],
            if (PlatformUtils.isWindows) ...[
              _buildPlatformCard(
                context,
                title: "Windows",
                subtitle: i18n("windows_desc"),
                icon: Remix.windows_line,
                children: [
                  _buildDownloadSection(context, title: i18n("exe_installer"), urls: controller.windowsSetupUrl.value),
                  const SizedBox(height: 16),
                  if (controller.windowsMsixUrl.value.isNotEmpty) ...[
                    _buildDownloadSection(
                      context,
                      title: i18n("msix_installer"),
                      urls: controller.windowsMsixUrl.value,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildDownloadSection(
                    context,
                    title: i18n("portable_package"),
                    urls: controller.windowsPortableUrl.value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            if (PlatformUtils.isMacOS) ...[
              _buildPlatformCard(
                context,
                title: "macOS",
                subtitle: i18n("macos_desc"),
                icon: Remix.macbook_line,
                children: [
                  _buildDownloadSection(context, title: i18n("macos_package"), urls: controller.macosUrl.value),
                ],
              ),
              const SizedBox(height: 20),
            ],
            if (PlatformUtils.isLinux) ...[
              _buildPlatformCard(
                context,
                title: "Linux",
                subtitle: i18n("linux_desc"),
                icon: Remix.ubuntu_line,
                children: [
                  _buildDownloadSection(context, title: i18n("deb_installer"), urls: controller.linuxDebUrl.value),
                  const SizedBox(height: 16),
                  _buildDownloadSection(context, title: i18n("portable_package"), urls: controller.linuxZipUrl.value),
                  const SizedBox(height: 16),
                  _buildDownloadSection(
                    context,
                    title: i18n("portable_tar_package"),
                    urls: controller.linuxTarGzUrl.value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            context.buildGroupTitle(i18n("update_log")),
            const SizedBox(height: 8),
            context.buildModernCard([
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Builder(
                          builder: (context) {
                            final theme = Theme.of(context);
                            final textTheme = theme.textTheme;
                            final isDark = theme.brightness == Brightness.dark;

                            final baseConfig = isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;

                            return MarkdownBlock(
                              data: controller.updateLog.value,
                              config: baseConfig.copy(
                                configs: [
                                  PConfig(textStyle: textTheme.bodyMedium ?? const TextStyle()),

                                  H1Config(
                                    style: (textTheme.titleLarge ?? const TextStyle()).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  H2Config(
                                    style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  H3Config(
                                    style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  //
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ],
        );
      }),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      key: const ValueKey('version-update-error'),
      physics: const PureLiveScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    i18n('version_update_failed_title'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n('version_update_failed_subtitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('version-update-retry'),
                    onPressed: controller.checkNewVersion,
                    icon: const Icon(Remix.refresh_line),
                    label: Text(i18n('retry')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return context.buildModernCard([
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.t12.copyWith(color: theme.hintColor.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    ]);
  }

  Widget _buildDownloadSection(BuildContext context, {required String title, required String urls}) {
    final String rawUrl = urls.trim();
    if (rawUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final String pureGithub = GitHubMirror.extractPureGithubUrl(rawUrl);
    final String officialUrl = pureGithub.isNotEmpty ? pureGithub : rawUrl;
    final String cfUrl = GitHubMirror.speedUpUrl(officialUrl);

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.t13.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 🌐 Git 官方源 (需VPN)
            Expanded(
              child: Tooltip(
                message: '从 GitHub 官方原站下载（需开启 VPN/科学上网）\n长按可复制链接',
                child: OutlinedButton.icon(
                  key: ValueKey('version-source-$title-git'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    foregroundColor: theme.colorScheme.onSurface,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: controller.downloadPending.value
                      ? null
                      : () => _startDownload(context, officialUrl),
                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: officialUrl));
                    if (context.mounted) _showMessage(context, 'copied_to_clipboard');
                  },
                  icon: const Icon(Remix.global_line, size: 16),
                  label: const Text(
                    '🌐 Git 官方源',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ⚡ CF 代理源 (免翻墙极速)
            Expanded(
              child: Tooltip(
                message: '通过 Cloudflare 边缘代理加速下载（国内免翻墙）\n长按可复制链接',
                child: FilledButton.icon(
                  key: ValueKey('version-source-$title-cf'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: controller.downloadPending.value
                      ? null
                      : () => _startDownload(context, cfUrl),
                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: cfUrl));
                    if (context.mounted) _showMessage(context, 'copied_to_clipboard');
                  },
                  icon: const Icon(Remix.flashlight_fill, size: 16),
                  label: const Text(
                    '⚡ CF 代理源',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startDownload(BuildContext context, String targetUrl) async {
    if (versionDownloadUri(targetUrl) == null) return;
    if (controller.downloadPending.value) return;
    controller.downloadPending.value = true;
    try {
      final handler = downloadRelease;
      if (handler != null) {
        await handler(targetUrl);
      } else {
        await downloadAndInstallApk(targetUrl);
      }
    } catch (_) {
      if (context.mounted) _showMessage(context, 'version_update_download_failed');
    } finally {
      if (!controller.isClosed) controller.downloadPending.value = false;
    }
  }

  void _showMessage(BuildContext context, String key) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(i18n(key))));
  }
}
