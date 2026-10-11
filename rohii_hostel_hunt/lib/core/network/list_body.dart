// Helpers for list responses, which come in more than one shape: a bare JSON list, a paginated
// object `{count, next, previous, results: [...]}`, or an object with a named list such as the
// wishlist's `{wishlist: [...], count: n}`. Accepting all of them lets the app work with an older
// or newer backend.

/// The items of a list response, or an empty list if the body is neither a list nor an object
/// holding a list under one of [keys].
List<dynamic> itemsFromBody(dynamic body, {List<String> keys = const ['results']}) {
  if (body is List) return body;
  if (body is Map) {
    for (final key in keys) {
      final value = body[key];
      if (value is List) return value;
    }
  }
  return const [];
}

/// How many items the server says there are in total (`count`), falling back to the number of
/// items received. A paginated response only carries the first page, so `count` is the true total.
int countFromBody(dynamic body, {List<String> keys = const ['results']}) {
  if (body is Map && body['count'] is int) return body['count'] as int;
  return itemsFromBody(body, keys: keys).length;
}
