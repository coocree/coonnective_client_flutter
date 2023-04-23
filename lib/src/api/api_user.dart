import 'package:coonnective_client_flutter/package.dart';
import 'package:coonnective_client_flutter/src/api/api_token_access_user.dart';
import 'package:coonnective_client_flutter/src/api/api_token_authorize_user.dart';

// Classe ApiUser representa um usuário da API e gerencia a autenticação e autorização desse usuário.
class ApiUser {
  // Atributos da classe
  String id = '';
  String apiKey = '';
  String email = '';
  String authUri = '';
  String tokenUri = '';
  String info = '';
  String auth = '';
  String services = '';
  String name = '';
  String role = '';
  String firstLetter = '';
  String clientId = ApiSecurity.encodeSha1('GUEST');

  // A instância única desta classe (singleton)
  static ApiUser? _instance;

  // Construtor factory que cria a instância única desta classe, se necessário, e inicializa com os dados do usuário.
  factory ApiUser({dynamic config}) {
    _instance ??= ApiUser._internalConstructor();

    if (config != null) {
      _instance!._init(config);
    }
    return _instance!;
  }

  // Construtor interno para criar a instância única desta classe.
  ApiUser._internalConstructor();

  // Método que inicializa os atributos da classe com os dados do usuário.
  void _init(dynamic value) async {
    if (value != null) {
      if (value['name'] != null && value['name'] != '') {
        name = value['name'];
        firstLetter = name.substring(0, 1);
      }
      if (value['_id'] != null && value['_id'] != '') {
        id = value['_id'];
      }
      if (value['role'] != null && value['role'] != '') {
        role = value['role'];
      }
      if (value['clientId'] != null && value['clientId'] != '') {
        clientId = value['clientId'];
      }
    }

    ApiStorage? apiStorage = await storage;
    if (clientId.isNotEmpty && apiStorage != null) {
      apiStorage.add('clientId', clientId);
    }
  }

  // Método para descartar a instância atual e criar uma nova instância com os dados padrão.
  void dispose() {
    name = '';
    id = '';
    role = '';
    firstLetter = '';
    clientId = ApiSecurity.encodeSha1('GUEST');
  }

  // Método para validar o token de autorização e obter o token de acesso e autenticação.
  void authorize() async {
    String? accessToken = await ApiUser.getAccessToken;
    if (!accessToken!.isNotEmpty) {
      ApiError apiError = ApiError(
          messages: ['Token de autorização da aplicação \'client\' inválido.'],
          code: "INVALID_CLIENT_AUTHORIZATION_TOKEN",
          module: "apiUser",
          path: "authorize",
          variables: accessToken);
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
          messages: ['Token de autorização da usuário \'user\' inválido.'],
          code: "INVALID_USER_AUTHORIZATION_TOKEN",
          module: "apiUser",
          path: "authorize",
          variables: accessToken);
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }

    await handleAuthorization(apiUserAuthorizeToken);
  }

  // Função para lidar com a autorização e obter o token de acesso.
  Future<void> handleAuthorization(ApiUserAuthorizeToken apiUserAuthorizeToken) async {
    bool isAuthorizeValid = await apiUserAuthorizeToken.authorize();
    if (!isAuthorizeValid) {
      ApiError apiError = ApiError(
          messages: ['Token de autorização da usuário \'user\' inválido'],
          code: "INVALID_USER_AUTHORIZATION_TOKEN",
          module: "apiUser",
          path: "handleAuthorization",
          variables: {"isAuthorizeValid": isAuthorizeValid});
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }
    await handleAccessToken(apiUserAuthorizeToken);
  }

  // Função para lidar com o token de acesso e validá-lo.
  Future<void> handleAccessToken(ApiUserAuthorizeToken apiUserAuthorizeToken) async {
    ApiUserAccessToken apiUserAccessToken = ApiUserAccessToken(apiUserAuthorizeToken);
    bool isTokenValid = await apiUserAccessToken.token();
    if (!isTokenValid) {
      ApiError apiError = ApiError(
          messages: ['Token de autorização da usuário \'user\' inválido'],
          code: "INVALID_USER_AUTHORIZATION_TOKEN",
          module: "apiUser",
          path: "handleAccessToken",
          variables: {"isAuthorizeValid": !isTokenValid});
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }
  }

// Método para retornar os dados básicos do usuário.
  resume() {
    return {"_id": id, "name": name};
  }

// Método para obter a instância do ApiStorage com o nome 'user'.
  static Future<ApiStorage?> get storage async {
    return await ApiStorage.init(name: 'user');
  }

// Método para obter o token de acesso do usuário.
  static Future<String?> get getAccessToken async {
    ApiStorage? apiStorage = await storage;
    return apiStorage!.read('accessToken');
  }

// Método para salvar o token de acesso do usuário.
  static void accessToken(String value) async {
    ApiStorage? apiStorage = await storage;
    apiStorage!.add('accessToken', value);
  }

// Método para obter o token de autenticação do usuário.
  static Future<String?> get getAuthToken async {
    ApiStorage? apiStorage = await storage;
    return apiStorage!.read('authToken');
  }

// Método para salvar o token de autenticação do usuário.
  static void authToken(String value) async {
    ApiStorage? apiStorage = await storage;
    apiStorage!.add('authToken', value);
  }

// Método para salvar o URI do servidor.
  static void serverUri(String value) async {
    ApiStorage? apiStorage = await storage;
    apiStorage!.add('serverUri', value);
  }

// Método para obter o URI do servidor.
  static Future<String?> get getServerUri async {
    ApiStorage? apiStorage = await storage;
    return apiStorage!.read('serverUri');
  }

// Método toString para representação da classe como uma string.
  @override
  String toString() {
    return 'Instance of ApiUser(clientId:$clientId, id:$id, name:$name, role:$role)';
  }
}
