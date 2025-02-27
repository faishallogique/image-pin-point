/// Represents the status of an operation result.
///
/// This class encapsulates information about whether an operation succeeded,
/// a descriptive message about the result, and an optional file path
/// if the operation involved a file.
class OperationResult {
  /// Indicates if the operation was successful.
  final bool isSuccess;

  /// A descriptive message about the operation result.
  final String message;

  /// Optional path to a file related to the operation.
  final String? filePath;

  /// Creates a new [OperationResult] instance.
  ///
  /// [isSuccess] indicates whether the operation succeeded.
  /// [message] provides details about the operation result.
  /// [filePath] is an optional path to a file related to the operation.
  OperationResult(
      {required this.isSuccess, required this.message, this.filePath});
}
