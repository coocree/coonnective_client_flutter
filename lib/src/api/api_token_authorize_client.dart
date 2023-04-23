import 'package:coonnective_client_flutter/package.dart';
import 'package:coonnective_client_flutter/src/api/api_client.dart';
import 'package:jose/jose.dart';

import 'api_connection.dart';

class ApiClientAuthorizeToken {
  String apiUri = '';
  String token = '';
  String clientId = '';
  String clientSecret = '';
  String code = '';
  String codeChallenge = '';
  String codeVerifier = '';
  String codeVerifier64 = '';
  String nonceToken = '';
  String state = '';
  String context = '';
  String subject = '';

  ApiClientAuthorizeToken(this.token) {
    if (token.isEmpty) {
      ApiError apiError = ApiError(
        code: "AUTHORIZE_TOKEN_NOT_FOUND",
        messages: ['Nenhum token de \'autorização\' foi definido na inicialização da aplicação.'],
        module: "apiClientAuthorizeToken",
        path: "ApiClientAuthorizeToken",
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

  ///Verifica se existe um token de autorização de cliente registrado na sessão local da aplicação
  ///Verifica se o token tem identificação do distribuidor e se o subject é do tipo auth_token
  Future<bool> get isValid async {
    bool isValid = false;
    if (token.isNotEmpty) {
      try {
        dynamic jwt = JsonWebToken.unverified(token);
        if (jwt.claims['iss'] != null && jwt.claims['sub'] == 'auth_token') {
          apiUri = jwt.claims['iss'];
          clientId = jwt.claims['cid'];
          context = jwt.claims['ctx'];
          subject = jwt.claims['sub'];
          clientSecret = ApiSecurity.encodeSha256((clientId) + (codeVerifier64));

          ApiStorage? apiStorage = await ApiClient.storage;

          if (apiStorage != null && (clientId.isEmpty)) {
            apiStorage.add('clientId', clientId);
          }
          isValid = true;
        }
      } catch (e) {
        ApiError apiError = ApiError(
          code: "AUTHORIZE_TOKEN_INVALID",
          messages: ['Token de autorização da aplicação \'client\' inválido.'],
          module: "apiClientAuthorizeToken",
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

  Future<bool> get ready async {
    ApiStorage? apiStorage = await ApiClient.storage;
    String clientId = apiStorage!.read('clientId') as String;
    bool ready = false;
    if (clientId.isEmpty) {
      ready = true;
    }
    return ready;
  }

  Future<bool> aclAuthorize() async {
    //Cria conexão com o servidor graphql
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
      }else{
        authorize.throwException();
      }
    } else {
      apiResponse.throwException();
    }
    return false;
  }
}
