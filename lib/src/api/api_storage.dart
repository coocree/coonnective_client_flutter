import 'package:get_storage/get_storage.dart';
import 'package:coonnective_client_flutter/package.dart';

// A classe ApiStorage é responsável por fornecer uma interface para armazenar e recuperar dados
// usando o pacote GetStorage e criptografando as informações armazenadas.
class ApiStorage {
  final String name;
  final String password;
  late GetStorage? storage;

  // Construtor da classe ApiStorage.
  ApiStorage({required this.name, this.password = 'default'}) {
    storage = GetStorage(ApiSecurity.encodeSha1(name));
  }

  // Método estático para inicializar o ApiStorage com o nome fornecido.
  // Retorna uma instância de ApiStorage se a inicialização for bem-sucedida, caso contrário retorna nulo.
  static Future<ApiStorage?> init({required String name}) async {
    if (name.isNotEmpty) {
      bool isStorage = await GetStorage.init(ApiSecurity.encodeSha1(name));
      if (isStorage) {
        return ApiStorage(name: name);
      }
    }
    return null;
  }

  // Método para adicionar um valor no armazenamento.
  // Recebe uma chave (key) e um valor (value) como argumentos.
  // O valor é criptografado antes de ser armazenado.
  Future<void> add(String key, String value) async {
    if (storage != null && key.isNotEmpty && value.isNotEmpty) {
      await storage!.write(ApiSecurity.encrypt(key, password)!, ApiSecurity.encrypt(value, password));
    } else {
      ApiError apiError = ApiError(
          messages: ["storage.add(?)"],
          code: "STORAGE_ADD_ERROR",
          module: "apiStorage",
          path: "add",
          variables: {"key": key, "value": value});
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }
  }

  // Método para remover um valor do armazenamento.
  // Recebe uma chave (key) como argumento e remove o valor correspondente do armazenamento.
  Future<void> remove(String key) async {
    if (storage != null && key.isNotEmpty) {
      await storage!.remove(key);
    } else {
      ApiError apiError = ApiError(
          messages: ["storage.remove(?)"],
          code: "STORAGE_REMOVE_KEY_FAILED",
          module: "apiStorage",
          path: "remove",
          variables: {"key": key});
      apiLog.e(
        apiError.toString(),
        apiError.code,
        StackTrace.current,
      );
      throw apiError.code;
    }
  }

  // Método para ler um valor do armazenamento.
  // Recebe uma chave (key) como argumento e retorna o valor descriptografado correspondente.
  // Retorna nulo se a chave não for encontrada.
  Future<String?> read(String key) async {
    String? result;
    if (storage != null) {
      String value = await storage!.read(ApiSecurity.encrypt(key, password)!);
      if (value.isNotEmpty) {
        result = ApiSecurity.decrypt(value, password);
      }
    }
    return result;
  }

  // Método para descartar o armazenamento.
  // Libera recursos e define o armazenamento como nulo.
  void dispose() {
    storage = null;
  }
}
