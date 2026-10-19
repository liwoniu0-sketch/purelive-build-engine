/**
 * PureLive & lzvideo Cloudflare High-Performance CDN Edge Worker
 * Domain: gh.lz1861.ccwu.cc
 * 专为内陆用户提供：
 * 1. 边缘强力缓存 (86400秒 CDN 缓存，免除重复拉取美国S3源站延迟)
 * 2. 满速流式传输与 HTTP 206 断点续传
 * 3. 智能跟随 GitHub 302 重定向
 */

const DEFAULT_OWNER = 'liwoniu-luzi';
const DEFAULT_REPO = 'lzvideo';

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request, event));
});

async function handleRequest(request, ctx) {
  const url = new URL(request.url);
  const pathname = url.pathname;

  // CORS 预检
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

  // 1. 直链通用前缀代理：兼容 /https://、/https:/、/http://、/http:/
  if (/^\/https?:\/+/i.test(pathname)) {
    const target = pathname.replace(/^\/+(https?):\/+/i, '$1://') + url.search;
    return handleProxy(request, target);
  }

  // 2. /gh/... 形式通用代理
  if (pathname.startsWith('/gh/')) {
    let target = pathname.substring(4) + url.search;
    if (!target.startsWith('http')) target = 'https://' + target;
    return handleProxy(request, target);
  }

  // 3. /api/version - 边缘极速直出最新版本元数据 (0ms延迟)
  if (pathname === '/api/version') {
    const rawVersionUrl = `https://raw.githubusercontent.com/${DEFAULT_OWNER}/${DEFAULT_REPO}/master/assets/version.json`;
    return handleProxy(request, rawVersionUrl, true);
  }

  // 4. /api/releases - 边缘极速直出全部历史发布记录
  if (pathname === '/api/releases') {
    const rawReleasesUrl = `https://raw.githubusercontent.com/${DEFAULT_OWNER}/${DEFAULT_REPO}/master/assets/releases.json`;
    return handleProxy(request, rawReleasesUrl, true);
  }

  // 5. 默认根目录 - 自动重定向到最新稳定版 arm64-v8a 极速下载
  if (pathname === '/' || pathname === '') {
    return new Response(JSON.stringify({
      name: "PureLive & lzvideo CDN Edge Accelerator",
      owner: DEFAULT_OWNER,
      repo: DEFAULT_REPO,
      status: "operational",
      domain: "gh.lz1861.ccwu.cc",
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

  // 6. 其他任意路径默认视为针对当前默认仓库的资源
  const fallbackTarget = `https://github.com/${DEFAULT_OWNER}/${DEFAULT_REPO}${pathname}${url.search}`;
  return handleProxy(request, fallbackTarget);
}

async function handleProxy(request, targetUrl, isJson = false) {
  try {
    const reqUrl = new URL(request.url);
    const isApk = targetUrl.toLowerCase().endsWith('.apk');
    const isDirectRaw = reqUrl.searchParams.get('raw') === '1';
    const country = request.cf ? (request.cf.country || '') : '';

    // 针对 APK 大文件，国内直连用户（CN）或未指定 raw 的浏览器下载，直接 302 重定向到国内满速专线节点，免除跨国 QoS 限速
    if (isApk && !isDirectRaw) {
      // 只要是国内用户或者普通网页下载，毫秒级 302 重定向到国内顶速 CDN
      const pure = targetUrl.replace(/^https?:\/\/+/i, '');
      return Response.redirect(`https://gh-proxy.com/https://${pure}`, 302);
    }

    const reqHeaders = new Headers(request.headers);
    reqHeaders.delete('Host');

    const enableCache = isApk || isJson;

    const fetchOptions = {
      method: request.method,
      headers: reqHeaders,
      redirect: 'follow',
    };

    if (enableCache) {
      fetchOptions.cf = {
        cacheEverything: true,
        cacheTtl: isApk ? 86400 : 300,
      };
    }

    const response = await fetch(targetUrl, fetchOptions);

    const respHeaders = new Headers(response.headers);
    respHeaders.set('Access-Control-Allow-Origin', '*');
    respHeaders.set('Access-Control-Allow-Methods', 'GET, HEAD, POST, OPTIONS');
    respHeaders.set('Access-Control-Allow-Headers', '*');
    respHeaders.set('Access-Control-Expose-Headers', 'Content-Length, Content-Range, Content-Disposition, CF-Cache-Status');

    if (enableCache && isApk) {
      respHeaders.set('Cache-Control', 'public, max-age=86400, s-maxage=86400');
    }

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: respHeaders
    });
  } catch (err) {
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
