import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:coonnective_client_flutter/package.dart';
import 'package:coonnective_client_flutter/src/api/api_connection.dart';
import 'package:coonnective_client_flutter/src/api/api_token_access_client.dart';
import 'package:coonnective_client_flutter/src/api/api_token_authorize_client.dart';
import 'package:coonnective_client_flutter/src/api/api_token_access_user.dart';
import 'package:coonnective_client_flutter/src/api/api_token_authorize_user.dart';
import 'package:flutter/foundation.dart';

// Classe ApiConnect gerencia a conexão com a API.
class ApiConnect {
  static late final ApiConnect _instance = ApiConnect._internalConstructor();

  late ApiClientAccessToken apiClientAccessToken;
  late ApiClientAuthorizeToken apiClientAuthorize;

  // Construtor da fábrica ApiConnect.
  factory ApiConnect([String authToken = ""]) {
    if (authToken.isNotEmpty) {
      _instance._init(authToken);
    }
    return _instance;
  }

  // Construtor interno ApiConnect.
  ApiConnect._internalConstructor();

  // Inicializa a conexão com a API.
  Future<void> _init(String authToken) async {
    apiClientAuthorize = ApiClientAuthorizeToken(authToken);
    if (!await apiClientAuthorize.isValid) {
      ApiError apiError = ApiError(
        code: "AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da aplicação \'client\' inválido.'],
        module: "apiClientAuthorizeToken",
        path: "_init",
        variables: {"apiClientAuthorize.isValid": apiClientAuthorize.isValid},
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

    bool isAuthorized = await apiClientAuthorize.aclAuthorize();
    if (!isAuthorized) {
      ApiError apiError = ApiError(
        code: "AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da aplicação \'client\' inválido.'],
        module: "apiClientAuthorizeToken",
        path: "_init",
        variables: {"isAuthorized": isAuthorized},
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

      apiClientAccessToken = ApiClientAccessToken(apiClientAuthorize);
      String accessToken = await apiClientAccessToken.token();
      if (!accessToken.isNotEmpty) {
        ApiError apiError = ApiError(
          code: "AUTHORIZE_TOKEN_INVALID",
          messages: ['Token de autorização da aplicação \'client\' inválido.'],
          module: "apiClientAuthorizeToken",
          path: "_init",
          variables: {"accessToken": accessToken},
        );
        apiLog.e(
          apiError.toString(),
          apiError.code,
          StackTrace.current,
        );
        throw apiError.code;
      }

      ApiUserAuthorizeToken apiUserAuthorizeToken = ApiUserAuthorizeToken(accessToken);
      if (!await apiUserAuthorizeToken.isValid) {
        ApiError apiError = ApiError(
          code: "AUTHORIZE_TOKEN_INVALID",
          messages: ['Token de autorização da usuário \'user\' inválido.'],
          module: "apiClientAuthorizeToken",
          path: "_init",
          variables: {"apiUserAuthorizeToken.isValid": apiUserAuthorizeToken.isValid, "accessToken": accessToken},
        );
        apiLog.e(
          apiError.toString(),
          apiError.code,
          StackTrace.current,
        );
        throw apiError.code;
      }

      bool isAuthorizeValid = await apiUserAuthorizeToken.authorize();

      if (!isAuthorizeValid) {
        ApiError apiError = ApiError(
          code: "AUTHORIZE_TOKEN_INVALID",
          messages: ['Token de autorização da usuário \'user\' inválido.'],
          module: "apiClientAuthorizeToken",
          path: "_init",
          variables: {"isAuthorizeValid": !isAuthorizeValid, "accessToken": accessToken},
        );
        apiLog.e(
          apiError.toString(),
          apiError.code,
          StackTrace.current,
        );
        throw apiError.code;
      }

      ApiUserAccessToken apiUserAccessToken = ApiUserAccessToken(apiUserAuthorizeToken);
      bool isTokenValid = await apiUserAccessToken.token();
      if (!isTokenValid) {
        ApiError apiError = ApiError(
          code: "AUTHORIZE_TOKEN_INVALID",
          messages: ['Token de autorização da aplicação \'client\' inválido.'],
          module: "apiClientAuthorizeToken",
          path: "_init",
          variables: {"isTokenValid": !isTokenValid, "accessToken": accessToken},
        );
        apiLog.e(
          apiError.toString(),
          apiError.code,
          StackTrace.current,
        );
        throw apiError.code;
      }
  }

  // Realiza uma consulta GraphQL.
  static Future<ApiResponse> query(String params, dynamic variable) async {
    String? accessToken = await ApiUser.getAccessToken;
    String? serverUri = await ApiUser.getServerUri;

    if (accessToken!.isNotEmpty && serverUri!.isNotEmpty) {
      ApiConnection apiConnection = ApiConnection(accessToken, serverUri);
      return apiConnection.query(params, variable);
    }

    return ApiResponse(
      success: false,
      errors: [
        ApiError(
          code: "QUERY_ERROR_",
          path: "query",
          messages: ["Falha na conexão com servidor API"],
          module: "apiConnect",
          variables: variable,
        )
      ],
    );
  }

  // Realiza uma mutação GraphQL.
  static Future<ApiResponse> mutation(String params, dynamic variable) async {
    String? accessToken = await ApiUser.getAccessToken;
    String? serverUri = await ApiUser.getServerUri;

    if (accessToken!.isNotEmpty && serverUri!.isNotEmpty) {
      ApiConnection apiConnection = ApiConnection(accessToken, serverUri);
      return apiConnection.mutation(params, variable);
    }

    return ApiResponse(
      success: false,
      errors: [
        ApiError(
          path: "mutation",
          messages: ["Falha na conexão com servidor API"],
          module: "apiConnect",
          code: "MUTATION_ERROR",
          variables: variable,
        ),
      ],
    );
  }

  // Executa a consulta ou mutação GraphQL e trata exceções.
  static Future<ApiResponse> exec({required dynamic apiGraphql}) async {
    bool hasConnectivity = await checkInternetConnection();
    ApiResponse apiResponse = ApiResponse();
    try {
      if (hasConnectivity) {
        apiResponse = await apiGraphql();
      } else {
        apiResponse = ApiResponse(
          errors: [
            ApiError(
              code: "NO_INTERNET_CONNECTION",
              module: "apiConnect",
              path: "exec",
              messages: ["Sem conexão com a Internet"],
            ),
          ],
        );
      }
    } catch (e) {
      ApiError apiError = ApiError(
        code: "EXCEPTION",
        module: "apiConnect",
        path: "exec",
        messages: ["Falha na conexão com servidor API", e.toString()],
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }
    return apiResponse;
  }

  // Verifica se há conexão com a Internet.
  static Future<bool> checkInternetConnection() async {
    bool hasConnectivity = false;
    //Verifica se é serviço web
    if (kIsWeb) {
      hasConnectivity = true;
    } else {
      ConnectivityResult connectivityResult = await (Connectivity().checkConnectivity());
      //Verifica se tem conexão mobile ou wifi
      if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
        hasConnectivity = true;
      }
    }
    return hasConnectivity;
  }
}
