# coonnective_client_flutter

O coonnective_client_flutter é um pacote de conexão GraphQL desenvolvido em Flutter, que permite a comunicação com um servidor GraphQL para enviar e receber dados. Ele é utilizado para facilitar o processo de comunicação entre o cliente e o servidor, além de garantir que as respostas recebidas sejam tratadas de forma adequada.

´´´dart
  static Future<ApiResponse> EventReset() async {
    final variable = {};
    String graphQL = r"""
mutation EventReset {
  EventReset(filter: {idEvent: "123"}) {
    result {
      idEvent
      status
    }
    error {
      code
      createdAt
      messages
      module
      path
      variables
    }
    elapsedTime
    success
  }
}
""";
    return await Api.dao(graphQL, variable);
  }
´´´

No código apresentado, temos a função EventReset() que realiza uma mutação no servidor GraphQL. O objetivo dessa mutação é resetar um evento identificado pelo ID "123". Para isso, a função define uma variável vazia e uma string contendo a query GraphQL a ser executada. A query é definida dentro da variável "graphQL", que contém o código GraphQL necessário para a execução da mutação.

´´´dart
    ApiResponse apiResponse = await EventReset();
    if (!apiResponse.isValid()) {
      apiResponse.throwException();
    }
    ApiEndpoint apiEndpoint = apiResponse.endpoint("EventReset");
    if (!apiEndpoint.isValid()) {
      apiEndpoint.throwException();
    }
    print(apiEndpoint.result);
´´´

Após a definição da query, a função chama o método "api.dao()" que é responsável por executar a query. Esse método recebe a query definida anteriormente e as variáveis definidas no início da função. Ele retorna um objeto do tipo "api.ResponseModel" que contém a resposta recebida do servidor GraphQL.

Em seguida, o código faz uma verificação para garantir que a resposta recebida seja válida. Caso contrário, é lançada uma exceção informando que algo deu errado na execução da query.

Após a verificação da resposta, o método "apiResponse.endpoint()" é chamado para obter o resultado da mutação. A variável "apiEndpoint" recebe o resultado retornado pelo método. Em seguida, outra verificação é realizada para garantir que o resultado obtido seja válido. Caso contrário, é lançada uma exceção informando que algo deu errado na execução da query.

Por fim, o resultado é impresso na tela através do comando "print(apiEndpoint.result)". Esse resultado contém o status do evento após o reset, que foi obtido como resposta da mutação realizada no servidor GraphQL.
