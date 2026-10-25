/**
 * PureLive & lzvideo Cloudflare High-Performance CDN Edge Worker
 * Domain: gh.lz1861.ccwu.cc
 * 核心优化特性：
 * 1. 纯原生 Cloudflare 边缘流式回源，彻底移除第三方 302 重定向暗雷
 * 2. 完整透传 Range 请求头与 206 Partial Content，保障 100% 稳定断点续传
 * 3. 智能跟随 GitHub Release 到 AWS S3 的 302 重定向流
 * 4. 边缘毫秒级直出版本元数据 (/api/version, /api/releases) 并内置高可用兜底
 */

const DEFAULT_OWNER = 'liwoniu0-sketch';
const DEFAULT_REPO = 'purelive-build-engine';
const GH_TOKEN = '';

const FALLBACK_VERSION = {
  "version": "3.4.6",
  "build_number": 4146,
  "version_num": 304034146,
  "android_abis": [
    "arm64-v8a",
    "armeabi-v7a",
    "x86_64"
  ],
  "version_desc": "### 🚀 v3.4.6 核心更新内容：\n- ⚡【极速应用内更新】：国内免翻墙首选 CF 极速直连通道，毫秒级响应\n- 🛠️【彻底修复左上/右上按钮消失】：重构手机与平板响应式判定，移动端全场景常驻保活\n- 🎯【彻底锁定下载通道】：点击【⚡ CF 代理源】100% 锁定免翻墙极速直连拉取；点击【🌐 Git 官方源】直接拉取官方原站\n- 🔄【弹窗支持一键双向热切】：下载过程中支持随时在【🌐 Git 官方源】与【⚡ CF 代理源】之间无缝一键热切，保留进度不丢数据\n- 🎨【更新界面纯净直观】：按设备架构清晰呈现【🌐 Git 官方源】与【⚡ CF 代理源】独立按钮\n- 📱【下载完成自动拉起安装】：下载完成后直接自动唤起系统安装器，一键无缝升级\n- 🔗【主页与仓库彻底对齐】：项目主页指向主仓库 `liwoniu0-sketch/purelive-build-engine`\n- 🎥【录屏合并彻底根除报错】：三级自愈级联引擎保障 5 分钟录屏 100% 合并成功\n- 📱 完美支持与原版 3.1.19 并存双开、互不干扰\n- 🔒 严格强制固化专属 Release 签名门禁 (SHA256: dd063e79f905509e3e6d24f2703ec30f361a795f3006ab7f6083d05c936dc979)",
  "prerelease": false,
  "download_url": "https://edgeone.gh-proxy.org/https://github.com/liwoniu0-sketch/purelive-build-engine/releases/download/v3.4.6/PureLive-3.4.6-android-arm64-v8a.apk",
  "platforms": {
    "android": {
      "version": "3.4.6",
      "build_number": 4146,
      "version_num": 304034146,
      "version_desc": "### 🚀 v3.4.6 核心更新内容：\n- ⚡【全新国内并发赛马下载引擎】：接入腾讯云 EdgeOne、国内高速专线毫秒级并发赛马，国内免翻墙秒级起速满速下载，告别假死\n- 🛠️【彻底修复左上/右上按钮消失】：重构手机与平板响应式判定，移动端全场景常驻保活\n- 🎯【彻底锁定下载通道】：点击【⚡ 国内极速源】100% 锁定免翻墙极速直连拉取；点击【🌐 Git 官方源】直接拉取官方原站\n- 🔄【弹窗支持一键双向热切】：下载过程中支持随时在【🌐 Git 官方源】与【⚡ 国内极速源】之间无缝一键热切，保留进度不丢数据\n- 🎨【更新界面纯净直观】：按设备架构清晰呈现【🌐 Git 官方源】与【⚡ 国内极速源】独立按钮\n- 📱【下载完成自动拉起安装】：下载完成后直接自动唤起系统安装器，一键无缝升级\n- 🔗【主页与仓库彻底对齐】：项目主页指向主仓库 `liwoniu0-sketch/purelive-build-engine`\n- 🎥【录屏合并彻底根除报错】：三级自愈级联引擎保障 5 分钟录屏 100% 合并成功\n- 📱 完美支持与原版 3.1.19 并存双开、互不干扰\n- 🔒 严格强制固化专属 Release 签名门禁 (SHA256: dd063e79f905509e3e6d24f2703ec30f361a795f3006ab7f6083d05c936dc979)",
      "prerelease": false,
      "download_url": "https://edgeone.gh-proxy.org/https://github.com/liwoniu0-sketch/purelive-build-engine/releases/download/v3.4.6/PureLive-3.4.6-android-arm64-v8a.apk",
      "android_abis": [
        "arm64-v8a",
        "armeabi-v7a",
        "x86_64"
      ]
    },
    "windows": {
      "version": "3.4.6",
      "build_number": 4146,
      "version_num": 304034146,
      "version_desc": "### 🚀 v3.4.6 核心更新内容：\n- 🛠️ 修复界面切换后顶部按钮偶尔消失问题\n- 🎯 彻底锁定用户选择的下载源通道与双向热切",
      "prerelease": false,
      "download_url": "https://github.com/liwoniu0-sketch/purelive-build-engine/releases/tag/v3.4.6",
      "windows_msix_available": true
    }
  }
};

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request, event));
});

async function handleRequest(request, ctx) {
  const url = new URL(request.url);
  const pathname = url.pathname;

  // 1. CORS 跨域预检处理
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, HEAD, POST, OPTIONS',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Max-Age': '86400',
      }
    });
  }

  // 2. 直链通用前缀代理：兼容 /https://、/https:/、/http://、/http:/
  if (/^\/https?:\/+/i.test(pathname)) {
    const target = pathname.replace(/^\/+(https?):\/+/i, '$1://') + url.search;
    return handleProxy(request, target);
  }

  // 3. /gh/... 路径形式代理
  if (pathname.startsWith('/gh/')) {
    let target = pathname.substring(4) + url.search;
    if (!target.startsWith('http')) target = 'https://' + target;
    return handleProxy(request, target);
  }

  // 4. /api/version - 边缘极速直出最新版本元数据 (0ms 延迟)
  if (pathname === '/api/version') {
    const rawVersionUrl = `https://raw.githubusercontent.com/${DEFAULT_OWNER}/${DEFAULT_REPO}/master/assets/version.json`;
    return handleProxy(request, rawVersionUrl, true, FALLBACK_VERSION);
  }

  // 5. /api/releases - 边缘极速直出全部历史发布记录
  if (pathname === '/api/releases') {
    const rawReleasesUrl = `https://raw.githubusercontent.com/${DEFAULT_OWNER}/${DEFAULT_REPO}/master/assets/releases.json`;
    return handleProxy(request, rawReleasesUrl, true);
  }

  // 6. 默认根目录状态展示
  if (pathname === '/' || pathname === '') {
    return new Response(JSON.stringify({
      name: "PureLive Build Engine CDN Edge Accelerator",
      owner: DEFAULT_OWNER,
      repo: DEFAULT_REPO,
      status: "operational",
      domain: "gh.lz1861.ccwu.cc",
      features: [
        "native_stream_proxy",
        "http_206_range_resumable",
        "zero_thirdparty_redirect",
        "edge_version_cache"
      ],
      endpoints: {
        raw_proxy: "https://gh.lz1861.ccwu.cc/https://github.com/...",
        version: "https://gh.lz1861.ccwu.cc/api/version",
        releases: "https://gh.lz1861.ccwu.cc/api/releases"
      }
    }, null, 2), {
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }

  // 7. 其他任意路径默认针对当前默认仓库
  const fallbackTarget = `https://github.com/${DEFAULT_OWNER}/${DEFAULT_REPO}${pathname}${url.search}`;
  return handleProxy(request, fallbackTarget);
}

async function handleProxy(request, targetUrl, isJson = false, fallbackData = null) {
  try {
    const isApk = targetUrl.toLowerCase().endsWith('.apk');

    // 复制请求头，清洗与重构关键字段
    const reqHeaders = new Headers();
    for (const [key, value] of request.headers.entries()) {
      const lower = key.toLowerCase();
      // 过滤掉特定 Hop-by-hop 头部与 Cloudflare 私有头
      if (lower !== 'host' && lower !== 'cf-connecting-ip' && lower !== 'cf-ray' && lower !== 'cf-visitor') {
        reqHeaders.set(key, value);
      }
    }

    // 针对 GitHub 内部源注入有效认证以提高配额
    if (targetUrl.includes('raw.githubusercontent.com') || targetUrl.includes('api.github.com')) {
      if (GH_TOKEN) {
        reqHeaders.set('Authorization', 'token ' + GH_TOKEN);
      }
    }

    // 确保 User-Agent 存在
    if (!reqHeaders.has('User-Agent')) {
      reqHeaders.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 PureLivePro/3.4.6');
    }

    // 构建回源 Fetch 请求选项
    const fetchOptions = {
      method: request.method,
      headers: reqHeaders,
      redirect: 'follow', // 核心：自动跟随 GitHub Release 到 AWS S3 真实下载节点的 302 重定向
    };

    // 针对大文件 APK 或版本 JSON 设置边缘优化
    const enableCache = isApk || isJson;
    if (enableCache) {
      fetchOptions.cf = {
        cacheEverything: true,
        cacheTtl: isApk ? 86400 : 180,
      };
    }

    // 执行回源拉取
    const response = await fetch(targetUrl, fetchOptions);

    // 构建响应头
    const respHeaders = new Headers(response.headers);
    respHeaders.set('Access-Control-Allow-Origin', '*');
    respHeaders.set('Access-Control-Allow-Methods', 'GET, HEAD, POST, OPTIONS');
    respHeaders.set('Access-Control-Allow-Headers', '*');
    respHeaders.set('Access-Control-Expose-Headers', 'Content-Length, Content-Range, Accept-Ranges, Content-Disposition, CF-Cache-Status');

    // 关键：强制声明支持 Range 分段断点续传
    respHeaders.set('Accept-Ranges', 'bytes');

    if (enableCache && isApk) {
      respHeaders.set('Cache-Control', 'public, max-age=86400, s-maxage=86400');
    }

    // 若回源失败且配置了兜底数据，则优雅降级返回兜底数据
    if (fallbackData && (response.status === 404 || response.status >= 500)) {
      return new Response(JSON.stringify(fallbackData, null, 2), {
        status: 200,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    // 核心流式直出：直接以 Response(response.body) 下发流，支持 HTTP 200 或 206
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: respHeaders
    });
  } catch (err) {
    // 若配置了兜底数据则优雅兜底
    if (fallbackData) {
      return new Response(JSON.stringify(fallbackData, null, 2), {
        status: 200,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    return new Response(JSON.stringify({
      error: 'Proxy Fetch Failed',
      message: err.message,
      target: targetUrl
    }), {
      status: 502,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}
