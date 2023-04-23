import 'package:coonnective_client_flutter/package.dart';

class ApiEndpoint {
  bool success = false;
  ApiError? error;
  dynamic result;

  ApiEndpoint(dynamic value) {
    print("ApiEndpoint: $value");

    if (value['success'] == null) {
      ApiError apiError = ApiError(
        code: "SUCCESS_NOT_FOUND",
        path: "ApiEndpoint",
        messages: ["O parametro 'success' não foi encontrado no resultado da query/mutation de interação com a base de dados."],
        module: "ApiEndpoint",
        variables: value,
      );

      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

    if (value != null) {
      if (value['error'] == null && value['result'] == null) {
        ApiError apiError = ApiError(
          code: "RESULT_NOT_FOUND",
          path: "ApiEndpoint",
          messages: ["O parametro 'result' não foi encontrado no resultado da query/mutation de interação com a base de dados."],
          module: "ApiEndpoint",
          variables: value,
        );

        apiLog.e(
          apiError.toString(),
          apiError.code,
          StackTrace.current,
        );
        throw apiError.code;
      }

      success = value['success'];
      result = value['result'];

      if (value['error'] != null) {
        error = ApiError(
          createdAt: value['error']['createdAt'],
          code: value['error']['code'],
          path: value['error']['path'],
          messages: value['error']['messages'],
          module: value['error']['module'],
          variables: value['error']['variables'],
        );
      }
    }
  }

  bool isValid() {
    return success && result != null && error == null;
  }

  void throwException() {
    if (error != null) {
      apiLog.e(
        error.toString(),
        error!.code,
        StackTrace.current,
      );
      throw error!.code;
    }
  }

  @override
  String toString() {
    return 'Instance of ApiEndpoint(result:$result, success:$success, error:$error)';
  }
}
