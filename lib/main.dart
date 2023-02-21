import 'dart:developer';

import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  OpenAI.apiKey = dotenv.get('OPENAIKEY');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Stream<OpenAIStreamCompletionModel>? m = null;
  ValueNotifier<String> _text = ValueNotifier<String>('');
  List<String> responses = [];
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  Stream<OpenAIStreamCompletionModel> generateStream(String prompt) {
    return OpenAI.instance.completion.createStream(
      model: "text-davinci-003",
      prompt: prompt,
      maxTokens: 100,
      n: 1,
      echo: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          backgroundColor: Color(0xff353541),
          appBar: AppBar(
            title: const Text('Flutter Demo Home Page'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                m != null
                    ? StreamBuilder(
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.active) {
                            log(snapshot.data!.choices.first.text.toString());
                            _text.value = _text.value +
                                snapshot.data!.choices.first.text.toString();
                            return ValueListenableBuilder(
                                valueListenable: _text,
                                builder: (context, value, child) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 1),
                                    child: Text(value,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  );
                                });
                          } else if (snapshot.hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Some error occured'),
                              ),
                            );
                            return const SizedBox();
                          } else if (snapshot.connectionState ==
                              ConnectionState.done) {
                            if (!responses.contains(_text.value)) {
                              responses.add(_text.value);
                              responses = List.from(responses.reversed);
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 1),
                              child: Text(_text.value,
                                  style: const TextStyle(color: Colors.white)),
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                        stream: m,
                      )
                    : const SizedBox(),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: responses.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: UniqueKey(),
                        onDismissed: (direction) {
                          responses.removeAt(index);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 1),
                          color: index % 2 == 0
                              ? const Color(0xff353541)
                              : const Color(0xff454652),
                          child: Text(
                            responses[index],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: _controller,
                style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Enter your text',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _text.value = '';
                          m = generateStream(_controller.text);
                        });
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
//dotenv.get('OPENAIKEY')