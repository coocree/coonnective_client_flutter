import 'package:coonnective_client_flutter/package.dart';
import 'package:jose/jose.dart';

import 'api_connection.dart';

class ApiUserAuthorizeToken {
  String apiUri = '';
  String token = '';
  String clientSecret = '';
  String code = '';
  String codeChallenge = '';
  String codeVerifier = '';
  String codeVerifier64 = '';
  String nonceToken = '';
  String state = '';

  ApiUserAuthorizeToken(this.token) {
    if (token.isEmpty) {
      ApiError apiError = ApiError(
        code: "AUTHORIZE_TOKEN_NOT_FOUND",
        messages: ['Nenhum token de \'autorização\' foi definido na inicialização da aplicação.'],
        module: "ApiUserAuthorizeToken",
        path: "ApiUserAuthorizeToken",
        variables: token,
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

    codeVerifier = ApiSecurity.randomBytes(32);
    codeVerifier64 = ApiSecurity.base64URLEncode(codeVerifier);
    codeChallenge = ApiSecurity.base64URLEncode(ApiSecurity.encodeSha256(codeVerifier64));

    state = ApiSecurity.randomBytes(16);
  }

  Future<bool> get isValid async {
    bool isValid = false;
    if (token.isNotEmpty) {
      try {
        dynamic jwt = JsonWebToken.unverified(token);
        if (jwt.claims['iss'] != null && jwt.claims['sub'] == 'access_token') {
          apiUri = jwt.claims['iss'];
          isValid = true;
        }
      } catch (e) {
        ApiError apiError = ApiError(
          code: "AUTHORIZE_TOKEN_INVALID",
          messages: ['Token de autorização de usuário \'user\' inválido.'],
          module: "ApiUserAuthorizeToken",
          path: "isValid",
          variables: token,
        );
        apiLog.e(
          apiError.toString(),
          apiError.code,
          StackTrace.current,
        );
        throw apiError.code;
      }
    }
    return isValid;
  }

  Future<bool> authorize() async {
    if (token.isEmpty) {
      ApiError apiError = ApiError(
        code: "AUTHORIZE_TOKEN_NOT_FOUND",
        messages: ['Nenhum token de \'autorização\' foi definido na inicialização da aplicação.'],
        module: "ApiUserAuthorizeToken",
        path: "authorize",
        variables: token,
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

    String clientId = ApiUser().clientId;

    try {
      var jwt = JsonWebToken.unverified(token);
      if (jwt.claims['iss'] != null) {
        apiUri = jwt.claims['iss'];
        clientSecret = ApiSecurity.encodeSha256((clientId) + (codeVerifier64));
      }
    } catch (e) {
      ApiError apiError = ApiError(
        code: "AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização de usuário \'Client token\' inválido.'],
        module: "ApiUserAuthorizeToken",
        path: "authorize",
        variables: token,
      );
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

    ApiConnection apiConnection = ApiConnection(token, apiUri);

    const String params = r"""
mutation AclAuthorize($input: AuthorizeInput!) {
  AclAuthorize(input: $input) {
    result {
      code
      nonceToken
      state
    }
    success
    error {
      code
      createdAt
      messages
      module
      path
      variables
    }
    elapsedTime
  }
}
""";
    ApiStorage? apiStorage = await ApiUser.storage;

    if (clientId.isNotEmpty && apiStorage != null) {
      apiStorage.add('clientId', clientId);
    }

    dynamic variable = {
      "input": {
        "clientId": clientId,
        "codeChallenge": codeChallenge,
        "responseType": "code",
        "scope": "mut:authorize",
        "state": state,
      }
    };

    ApiResponse apiResponse = await apiConnection.mutation(params, variable);
    if (apiResponse.isValid()) {
      ApiEndpoint authorize = apiResponse.endpoint('AclAuthorize');
      if (authorize.isValid()) {
        if (authorize.result['state'] == state) {
          code = authorize.result['code'];
          nonceToken = authorize.result['nonceToken'];
          return true;
        }
      }
      else{
        authorize.throwException();
      }
    } else {
      apiResponse.throwException();
    }
    return false;
  }
}
