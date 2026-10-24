import 'dart:io' show Platform;

import 'package:flutter/material.dart';

class PlatformUtils {
  PlatformUtils._();
  static bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static bool get isDesktopNotMac => (Platform.isWindows || Platform.isLinux) && !Platform.isMacOS;

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static bool isMobileWidth(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
  }

  /// 判断当前环境是否呈现平板/桌面宽屏侧边栏布局
  static bool isTabletLayout(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    // 桌面端以 680 宽度为分界线（大于 680 时有左侧 NavigationRail 侧边栏）
    if (isDesktop) {
      return media.width > 680;
    }
    // 移动端（手机/平板）：必须最短边 >= 600（真实大屏平板设备）且当前宽度 > 680 时才呈现侧边栏，
    // 普通手机无论是竖屏还是横屏（最短边普遍 < 500），永远属于手机移动端布局，防止被误判为平板。
    return media.shortestSide >= 600 && media.width > 680;
  }

  /// 判断当前页面是否应在 AppBar 呈现左上角菜单与右上角操作按钮（侧边栏未生效时必须呈现）
  static bool shouldShowAppBarActions(BuildContext context) {
    return !isTabletLayout(context);
  }

  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;

  static T select<T>({required T desktop, required T mobile}) {
    return isDesktop ? desktop : mobile;
  }
}
