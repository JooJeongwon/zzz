sealed class AppError {
  const AppError();
}

class SessionExpiredError extends AppError {
  const SessionExpiredError();
}

class UpdateFailedError extends AppError {
  const UpdateFailedError();
}

class NetworkError extends AppError {
  final String message;
  const NetworkError(this.message);
}

class UnknownError extends AppError {
  final String message;
  const UnknownError(this.message);
}
