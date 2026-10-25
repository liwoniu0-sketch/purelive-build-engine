class GitHubMirror {
  final String owner;
  final String repo;
  final String branch;

  GitHubMirror({required this.owner, required this.repo, this.branch = 'master'});

  String rawUrl(String filePath) {
    return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$filePath';
  }

  /// jsdelivr CDN
  String jsdelivr(String filePath) {
    return 'https://cdn.jsdelivr.net/gh/$owner/$repo@$branch/$filePath';
  }

  String jsdelivrFastly(String filePath) {
    return 'https://fastly.jsdelivr.net/gh/$owner/$repo@$branch/$filePath';
  }

  static const List<String> _rawPrefixes = [
    'https://gh.lz1861.ccwu.cc/',
  ];

  List<String> mirrors(String filePath) {
    final raw = rawUrl(filePath);

    return List.unmodifiable({
      'https://gh.lz1861.ccwu.cc/$raw',
      raw,
      // 静态资源公共 CDN 备用
      jsdelivr(filePath),
      jsdelivrFastly(filePath),
    });
  }

  static const List<Map<String, String>> domesticMirrorNodes = [
    {
      'name': '⚡ 腾讯云 EdgeOne',
      'prefix': 'https://edgeone.gh-proxy.org/',
    },
    {
      'name': '🚀 国内高速专线',
      'prefix': 'https://gh-proxy.com/',
    },
    {
      'name': '🌐 国内 CDN 镜像',
      'prefix': 'https://cdn.gh-proxy.org/',
    },
    {
      'name': '⚡ CF 备用代理',
      'prefix': 'https://gh.lz1861.ccwu.cc/',
    },
  ];

  static String fixRepoUrl(String url) {
    if (url.contains('liwoniu-luzi/lzvideo')) {
      return url.replaceAll('liwoniu-luzi/lzvideo', 'liwoniu0-sketch/purelive-build-engine');
    }
    return url;
  }

  static String extractPureGithubUrl(String url) {
    final clean = fixRepoUrl(url.trim());
    final index = clean.indexOf('https://github.com/');
    if (index >= 0) {
      return clean.substring(index);
    }
    final httpIndex = clean.indexOf('http://github.com/');
    if (httpIndex >= 0) {
      return clean.substring(httpIndex);
    }
    final rawIndex = clean.indexOf('https://raw.githubusercontent.com/');
    if (rawIndex >= 0) {
      return clean.substring(rawIndex);
    }
    return clean;
  }

  static String speedUpUrl(String originalUrl) {
    final pure = extractPureGithubUrl(originalUrl);
    if (pure.contains('github.com/') || pure.contains('githubusercontent.com/')) {
      return 'https://edgeone.gh-proxy.org/$pure';
    }
    return originalUrl;
  }

  static List<Map<String, String>> buildDomesticCandidateNodes(String originalUrl) {
    final pure = extractPureGithubUrl(originalUrl);
    if (!pure.contains('github.com/') && !pure.contains('githubusercontent.com/')) {
      return [
        {'name': '默认下载源', 'url': originalUrl}
      ];
    }
    return domesticMirrorNodes.map((node) {
      return {
        'name': node['name']!,
        'url': '${node['prefix']}$pure',
      };
    }).toList();
  }
}
