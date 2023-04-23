import 'package:coonnective_client_flutter/package.dart';

class ApiParams {
  late String module;
  late String path;
  late String queryString;
  List<String> errors = [];

  ApiParams(String value) {
    queryString = value.trim();
    module = _extractModule(queryString);
    path = _extractPath(queryString);
  }

  String _extractModule(String queryString) {
    return _capitalize(queryString.split(' ')[0]);
  }

  String _extractPath(String queryString) {
    RegExp regExp = RegExp(r'([a-zA-Z_]+\()');
    Match? match = regExp.firstMatch(queryString);
    if (match != null) {
      String operation = match.group(1)!;
      return operation.substring(0, operation.length - 1);
    }
    return '';
  }

  String _capitalize(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input.substring(0, 1).toUpperCase() + input.substring(1);
  }

  bool isValid() {
    if (!queryString.contains('result {')) {
      errors.add('Campo "result" ausente na string de consulta');
    }

    if (!queryString.contains('success')) {
      errors.add('Campo "success" ausente na string de consulta');
    }

    if (queryString.contains('error {')) {
      if (!queryString.contains('code')) {
        errors.add('Campo "code" ausente no bloco "error" da string de consulta');
      }
      if (!queryString.contains('createdAt')) {
        errors.add('Campo "createdAt" ausente no bloco "error" da string de consulta');
      }
      if (!queryString.contains('messages')) {
        errors.add('Campo "messages" ausente no bloco "error" da string de consulta');
      }
      if (!queryString.contains('module')) {
        errors.add('Campo "module" ausente no bloco "error" da string de consulta');
      }
      if (!queryString.contains('path')) {
        errors.add('Campo "path" ausente no bloco "error" da string de consulta');
      }
      if (!queryString.contains('variables')) {
        errors.add('Campo "variables" ausente no bloco "error" da string de consulta');
      }
    } else {
      errors.add('Bloco "error" ausente na string de consulta');
    }

    if (!queryString.contains('elapsedTime')) {
      errors.add('Campo "elapsedTime" ausente na string de consulta');
    }

    _validateField();

    return errors.isEmpty;
  }

  _validateField() {
    if (errors.isNotEmpty) {
      ApiError apiError = ApiError(
        code: "INVALID_API_PARAMS",
        messages: errors,
        module: module,
        path: path,
        variables: null,
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

    if (module.toLowerCase() != "query" && module.toLowerCase() != "mutation") {
      ApiError apiError = ApiError(
        code: "INVALID_MODULE",
        messages: ["Não foi encontrado definção de module"],
        module: "apiParams",
        path: "isValid",
        variables: null,
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

    if (module.toLowerCase() != "query" && module.toLowerCase() != "mutation") {
      ApiError apiError = ApiError(
        code: "INVALID_PATH",
        messages: ["Não foi encontrado definção de path"],
        module: "apiParams",
        path: "isValid",
        variables: null,
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }
  }

  @override
  String toString() {
    return 'Instance of ApiParams(module:$module, path: $path, errors: $errors)';
  }
}
