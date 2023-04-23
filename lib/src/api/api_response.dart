/*
Este é o código-fonte da classe ApiResponse que é usada para encapsular a resposta das chamadas da API.
*/

import 'package:coonnective_client_flutter/src/api/api_endpoint.dart';

import 'api.dart';
import 'api_error.dart';

class ApiResponse {
  final bool success; // Indica se a chamada foi bem-sucedida ou não
  final List<ApiError>? errors; // Lista de erros retornados pela API, se houver
  final dynamic data; // Os dados retornados pela API

  final Map<String, ApiError> _errors = {}; // Mapa de erros, indexado pelo caminho do erro

  ApiResponse({
    this.success = false,
    this.errors,
    this.data,
  }) {
    if (errors != null) {
      for (var item in errors!) {
        _errors[item.path] = item; // Adiciona cada erro ao mapa de erros
      }
    }
  }

// Retorna o resultado da chamada da API para um endpoint específico
  dynamic result(String endpoint) {
    if (data != null) {
      dynamic response = data[endpoint];
      if (response != null) {
        return data[endpoint]['result'];
      }
    }
  }

// Retorna o erro da chamada da API para um endpoint específico
  dynamic resultError(String endpoint) {
    if (data != null) {
      dynamic response = data[endpoint];
      if (response != null) {
        return data[endpoint]['error'];
      }
    }
  }

// Retorna as informações de página da chamada da API para um endpoint específico
  dynamic pageInfo(String endpoint) {
    if (data != null) {
      dynamic response = data[endpoint];
      if (response != null) {
        return data[endpoint]['pageInfo'];
      }
    }
  }

// Retorna o endpoint da API especificado pelo nome
  ApiEndpoint endpoint(String name) {
    dynamic endpoint;
    endpoint = data[name];

    if(endpoint == null) {
      // Se o endpoint não for encontrado, lança um erro
      ApiError apiError = ApiError(
        code: "ENDPOINT_NOT_FOUND",
        path: "apiResponse",
        messages: ["O endpoint '$name' não foi encontrado no resultado da query/mutation de interação com a base de dados."],
        module: "ApiResponse",
        variables: data,
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }
    return ApiEndpoint(endpoint);
  }

// Retorna verdadeiro se a chamada da API foi bem-sucedida e não houve erros
  bool isValid() {
    if (success && _errors.isEmpty) {
      return true;
    }
    return false;
  }

// Lança uma exceção se houver erros na resposta da API
  void throwException() {
    if (errors != null) {
      for (var item in errors!) {
        apiLog.e(
          item.toString(),
          item.code,
          StackTrace.current,
        );
        throw item.code;
      }
    }
  }

  @override
  String toString() {
    return 'Instance of ApiResponse(data:$data, success:$success, errors:$errors)';
  }
}