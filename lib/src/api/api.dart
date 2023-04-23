import 'package:coonnective_client_flutter/package.dart';
import 'package:coonnective_client_flutter/src/api/api_params.dart';
import 'package:logger/logger.dart';

Logger apiLog = Logger(
  printer: PrettyPrinter(),
);

class Api {
  static Future<ApiResponse> dao(
    String graphQL,
    dynamic variable,
  ) async {
    ApiParams apiParams = ApiParams(graphQL);

    if (apiParams.isValid()) {
      if (apiParams.path.toLowerCase() == 'query') {
        ApiResponse apiResponse = await ApiConnect.exec(
          apiGraphql: () async {
            return await ApiConnect.query(graphQL, variable);
          },
        );
        return apiResponse;
      }

      return await ApiConnect.exec(
        apiGraphql: () async {
          return await ApiConnect.mutation(graphQL, variable);
        },
      );
    }

    return ApiResponse(
      success: false,
      errors: [
        ApiError(
          path: apiParams.path,
          messages: ["Falha de configuração do graphQL"],
          module: apiParams.module,
          code: "DAO_ERROR",
          variables: variable,
        ),
      ],
    );
  }
}
