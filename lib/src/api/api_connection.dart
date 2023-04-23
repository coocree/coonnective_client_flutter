import 'package:coonnective_client_flutter/package.dart';
import 'package:coonnective_client_flutter/src/api/api_params.dart';
import 'package:coonnective_client_flutter/src/api/api_query_result.dart';
import 'package:graphql/client.dart';

class ApiConnection {
  late GraphQLClient _graphQLClient;

  ApiConnection(String token, String serverUri) {
    //serverUri = "http://192.168.1.30:4600";
    //serverUri = "http://192.168.1.34:4600/query";
    //serverUri = "https://geopoint.aegis.app.br/query";
    serverUri = "http://localhost:4600/api-connect";
    //serverUri = "http://api.kdltelegestao.com/query";
    print("serverUri -->>:" + serverUri);

    final HttpLink httpLink = HttpLink(serverUri);
    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    _graphQLClient = GraphQLClient(
      link: authLink.concat(httpLink),
      cache: GraphQLCache(),
    );
  }

  Future<ApiResponse> query(
      String params,
      dynamic variables, {
        FetchPolicy fetchPolicy = FetchPolicy.cacheFirst,
      }) async {

    late ApiResponse apiResponse;
    ApiParams apiParams = ApiParams(params);
    try {
      final options = QueryOptions(
        document: gql(params),
        variables: Map<String, dynamic>.from(variables),
        fetchPolicy: fetchPolicy,
      );

      QueryResult queryResult = await _graphQLClient.query(options);
      if (queryResult.hasException) {
        ApiQueryResult apiQueryResult = ApiQueryResult(queryResult.toString());
        ApiError apiError = ApiError(
          createdAt: apiQueryResult.timestamp!.toIso8601String(),
          code: apiQueryResult.code!,
          messages: apiQueryResult.errors,
          module: apiParams.module,
          path: apiParams.path,
          variables: variables,
        );
        apiLog.e(
          apiError.toString(),
          apiError.code,
          StackTrace.current,
        );
        //throw apiError.code;
      } else {
        apiResponse = ApiResponse(success: true, data: queryResult.data);
      }
    } catch (e) {
      ApiError apiError = ApiError(
        code: "GRAPHQL_QUERY_FAILED",
        messages: ["GraphQLClient.query() falhou"],
        module: apiParams.module,
        path: apiParams.path,
        variables: variables,
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

  Future<ApiResponse> mutation(
    String params,
    dynamic variables, {
    FetchPolicy fetchPolicy = FetchPolicy.cacheFirst,
  }) async {
    late ApiResponse apiResponse;

    ApiParams apiParams = ApiParams(params);
    try {
      final options = MutationOptions(
        document: gql(params),
        variables: Map<String, dynamic>.from(variables),
        fetchPolicy: fetchPolicy,
      );

      QueryResult queryResult = await _graphQLClient.mutate(options);

      if (queryResult.hasException) {
        ApiQueryResult apiQueryResult = ApiQueryResult(queryResult.toString());
        ApiError apiError = ApiError(
          createdAt: apiQueryResult.timestamp!.toIso8601String(),
          code: apiQueryResult.code!,
          messages: apiQueryResult.errors,
          module: apiParams.module,
          path: apiParams.path,
          variables: variables,
        );
        apiLog.e(
          apiError.toString(),
          apiError.code,
          StackTrace.current,
        );
        throw apiError.code;
      } else {
        apiResponse = ApiResponse(success: true, data: queryResult.data);
      }
    } catch (e) {
      ApiError apiError = ApiError(
        code: "GRAPHQL_MUTATE_FAILED",
        messages: ["GraphQLClient.mutate() falhou"],
        module: apiParams.module,
        path: apiParams.path,
        variables: variables,
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
}
