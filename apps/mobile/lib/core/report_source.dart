import 'dart:io';
import 'dart:typed_data';

Uri reportUri(String value) {
  final u = Uri.tryParse(value);
  if (u == null ||
      u.scheme != 'https' ||
      u.host.isEmpty ||
      u.userInfo.isNotEmpty ||
      u.hasFragment ||
      u.hasPort && u.port != 443 ||
      value.length > 2048 ||
      u.host == 'localhost' ||
      u.host.endsWith('.local')) {
    throw const FormatException('Use a direct HTTPS report file link.');
  }
  return u;
}

bool publicReportAddress(InternetAddress a) {
  final b = a.rawAddress;
  if (a.type == InternetAddressType.IPv4) {
    return b[0] != 0 &&
        b[0] != 10 &&
        b[0] != 127 &&
        b[0] < 224 &&
        !(b[0] == 169 && b[1] == 254) &&
        !(b[0] == 172 && b[1] >= 16 && b[1] <= 31) &&
        !(b[0] == 192 && b[1] == 168) &&
        !(b[0] == 100 && b[1] >= 64 && b[1] <= 127);
  }
  return (b[0] & 0xe0) ==
      0x20; // Only global unicast IPv6; no mapped/loopback/link-local targets.
}

Future<Uint8List> downloadReport(String value) async {
  var uri = reportUri(value);
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    for (var hop = 0; hop < 4; hop++) {
      final addresses = await InternetAddress.lookup(uri.host)
          .timeout(const Duration(seconds: 12));
      if (addresses.isEmpty || addresses.any((a) => !publicReportAddress(a))) {
        throw const FormatException('Use a publicly reachable report source.');
      }
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/pdf,image/jpeg,image/png',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        final next = response.headers.value(HttpHeaders.locationHeader);
        if (next == null) {
          throw const FormatException('Report redirect unavailable.');
        }
        uri = reportUri(uri.resolve(next).toString());
        continue;
      }
      if (response.statusCode != 200 || response.contentLength > 5242880) {
        throw const FormatException('Report unavailable or larger than 5 MB.');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        if (bytes.length + chunk.length > 5242880) {
          throw const FormatException('Use a report up to 5 MB.');
        }
        bytes.add(chunk);
      }
      return bytes.takeBytes();
    }
    throw const FormatException('Too many report redirects.');
  } finally {
    client.close(force: true);
  }
}
