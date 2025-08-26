class AppException implements Exception {
  final String? message;
  final String? _prefix;

  AppException([this.message, this._prefix]);

  @override
  String toString() => '$_prefix $message';
}

class FetchDataException extends AppException {
  FetchDataException([message]) : super(message, 'Error During Communication: ');
}

class BadRequestException extends AppException {
  BadRequestException([message]) : super(message, 'Invalid Request: ');
}

class UnauthorisedException extends AppException {
  UnauthorisedException([message]) : super(message, 'Unauthorised: ');
}

class InvalidInputException extends AppException {
  InvalidInputException([message]) : super(message, 'Invalid Input: ');
}

class ConflictException extends AppException {
  ConflictException([message]) : super(message, 'Conflict: ');
}

class NotFoundException extends AppException {
  NotFoundException([message]) : super(message, 'Not Found: ');
}
