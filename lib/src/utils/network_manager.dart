import 'package:http/http.dart' as http;
import 'package:http/retry.dart' as http_retry;

///
final http.Client networkManager = http_retry.RetryClient.withDelays(
  http.Client(),
  const <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
  ],
);
