import 'package:coonnective_client_flutter/package.dart';
import 'package:flutter/material.dart';

Future<void> initServices() async {
  String token =
      "";
  ApiConnect(token);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();
  runApp(const Example());
}

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExamplePage(),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            ApiResponse apiResponse = await EventReset();
            if (!apiResponse.isValid()) {
              apiResponse.throwException();
            }
            ApiEndpoint apiEndpoint = apiResponse.endpoint("EventReset");
            if (!apiEndpoint.isValid()) {
              apiEndpoint.throwException();
            }
            print(apiEndpoint.result);
          },
          child: const Text("hasConnection"),
        ),
      ),
    );
  }
}
