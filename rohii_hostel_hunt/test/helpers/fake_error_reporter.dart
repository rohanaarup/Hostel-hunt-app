import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';

class RecordedBreadcrumb {
  RecordedBreadcrumb(this.category, this.message, this.data);
  final String category;
  final String message;
  final Map<String, Object?>? data;
}

class FakeErrorReporter implements ErrorReporter {
  final List<Object> reported = [];
  final List<String?> hints = [];
  final List<RecordedBreadcrumb> breadcrumbs = [];

  @override
  void report(Object error, StackTrace? stack, {String? hint}) {
    reported.add(error);
    hints.add(hint);
  }

  @override
  void breadcrumb({
    required String category,
    required String message,
    Map<String, Object?>? data,
  }) {
    breadcrumbs.add(RecordedBreadcrumb(category, message, data));
  }
}
