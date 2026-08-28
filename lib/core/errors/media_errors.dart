// Media processing errors with proper categorization
abstract class MediaError implements Exception {
  final String message;
  final String? technicalDetails;
  final dynamic originalError;

  const MediaError(this.message, {this.technicalDetails, this.originalError});

  @override
  String toString() => 'MediaError: $message${technicalDetails != null ? ' ($technicalDetails)' : ''}';
}

class UnsupportedFormatError extends MediaError {
  const UnsupportedFormatError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class InsufficientStorageError extends MediaError {
  const InsufficientStorageError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class PermissionDeniedError extends MediaError {
  const PermissionDeniedError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class InvalidInputError extends MediaError {
  const InvalidInputError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class ProcessingFailedError extends MediaError {
  const ProcessingFailedError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class OperationCancelledError extends MediaError {
  const OperationCancelledError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class UnsupportedPlatformError extends MediaError {
  const UnsupportedPlatformError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class UnsupportedCodecError extends MediaError {
  const UnsupportedCodecError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class NativeDependencyUnavailableError extends MediaError {
  const NativeDependencyUnavailableError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class CorruptedFileError extends MediaError {
  const CorruptedFileError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}

class TimeoutError extends MediaError {
  const TimeoutError(String message, {String? technicalDetails, dynamic originalError})
      : super(message, technicalDetails: technicalDetails, originalError: originalError);
}