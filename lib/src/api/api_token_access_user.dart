import 'package:coonnective_client_flutter/package.dart';
import 'package:jose/jose.dart';

import 'api_connection.dart';
import 'api_token_authorize_user.dart';

class ApiUserAccessToken {
  ApiUserAuthorizeToken apiUserAuthorize;
  String clientId = '';
  String tokenType = '';
  String expiresIn = '';
  String accessToken = '';
  String refreshToken = '';
  bool isValid = false;

  ApiUserAccessToken(this.apiUserAuthorize);

  Future<bool> token() async {
    String clientId = ApiUser().clientId;
    ApiConnection apiConnection = ApiConnection(apiUserAuthorize.nonceToken, apiUserAuthorize.apiUri);

    const String params = r"""
mutation AclToken($input: TokenInput!) {
  AclToken(input: $input) {
    result {
      accessToken
      expiresIn
      refreshToken
      tokenType
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
    dynamic variable = {
      "input": {
        "clientId": clientId,
        "clientSecret": apiUserAuthorize.clientSecret,
        "code": apiUserAuthorize.code,
        "codeVerifier": apiUserAuthorize.codeVerifier64,
        "grantType": 'authorization_code'
      }
    };

    ApiResponse apiResponse = await apiConnection.mutation(params, variable);

    if (apiResponse.isValid()) {
      ApiEndpoint token = apiResponse.endpoint('AclToken');

      if (token.isValid()) {
        tokenType = token.result['tokenType'];
        expiresIn = token.result['expiresIn'];
        accessToken = token.result['accessToken'];
        refreshToken = token.result['refreshToken'];
        isValid = true;

        ApiStorage? apiStorage = await ApiUser.storage;
        if (apiStorage != null) {
          apiStorage.add('accessToken', accessToken);
          apiStorage.add('refreshToken', refreshToken);

          try {
            var jwt = JsonWebToken.unverified(accessToken);
            if (jwt.claims['iss'] != null) {
              apiStorage.add('serverUri', jwt.claims['iss']);
            }
          } catch (e) {
            ApiError apiError = ApiError(
              code: "ACCESS_TOKEN_INVALID",
              messages: ['Token de inicialização \'User token\' inválido.'],
              module: "ApiUserAccessToken",
              path: "token",
              variables: accessToken,
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
      } else {
        token.throwException();
      }
    } else {
      apiResponse.throwException();
    }
    return false;
  }
}
