/// Defines possible states for [ValueResponse].
enum ValueResponseStatus { empty, success, error }

/// Represents the end state of an async operation.
class ValueResponse<T> {
  final T? _data;
  final ExceptionWrapper? _error;
  final ValueResponseStatus status;
  final Exception? _exception;

  T get data => _data!;

  ExceptionWrapper get error => _error!;

  bool get isEmpty => status == ValueResponseStatus.empty;

  bool get isSuccess => status == ValueResponseStatus.success;

  bool get isError => status == ValueResponseStatus.error;

  /// Empty constructor for when no result has been returned.
  ValueResponse.empty()
      : status = ValueResponseStatus.empty,
        _data = null,
        _error = null,
        _exception = null;

  /// Use when the operation succeeds and data needs to be sent.
  ValueResponse.success([T? data])
      : status = ValueResponseStatus.success,
        _data = data,
        _error = null,
        _exception = null;

  /// Use when the operation fails and error message needs to be sent.
  ValueResponse.error(String message, [Object? baseException])
      : status = ValueResponseStatus.error,
        _data = null,
        _error = ExceptionWrapper(message, baseException: baseException),
        _exception = null;

  /// Use when the operation fails due to some exception.
  ValueResponse.exception(ExceptionWrapper error)
      : status = ValueResponseStatus.error,
        _data = null,
        _error = error,
        _exception = null;

  ValueResponse.exceptionRaw(Exception exception)
      : status = ValueResponseStatus.error,
        _data = null,
        _error =
            ExceptionWrapper(exception.toString(), baseException: exception),
        _exception = exception;
}

/// Custom exception that can be thrown/passed anywhere in the project.
/// Any exception must be wrapped with this and define a [message] to
/// be displayed/logged and a [code] that is unique to the error.
/// [stackTrace] tags along so that it can be reported to any crashlytics
/// service.
class ExceptionWrapper implements Exception {
  final String message;
  final String code;
  final StackTrace? stackTrace;
  final Object? baseException;

  ExceptionWrapper(
    this.message, {
    this.baseException,
    this.stackTrace,
    this.code = '',
  });

  @override
  String toString() {
    return 'ExceptionWrapper: [$code] $message';
  }
}
