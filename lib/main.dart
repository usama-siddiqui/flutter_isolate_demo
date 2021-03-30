import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  static Timer _timer;

  @override
  void initState() {
    //createIsolate();
    //createComputeFunction();
    _firstIsolate();
    _secondIsolate();
    super.initState();
  }

  _firstIsolate() async {
    ReceivePort receivePort = ReceivePort();
    receivePort.listen((message) {
      print(message.toString() + "\n");
    });

    await Isolate.spawn(timer, receivePort.sendPort);
  }

  _secondIsolate() async {
    ReceivePort receivePort = ReceivePort();
    receivePort.listen((message) {
      print(message.toString() + "\n");
    });

    await Isolate.spawn(timer, receivePort.sendPort);
  }

  static timer(SendPort sendPort) {
   _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if(t.tick == 10){
       _timer.cancel();
      }else{
         sendPort.send(t.tick);
      }
      
      });
  }

  createComputeFunction() async {
    String email = await compute(computeFunction, "https://randomuser.me/api/");
    print(email);
  }

  static Future<String> computeFunction(String url) async {
    var response = await http.get(url);
    var json = jsonDecode(response.body);
    return json["results"][0]["email"];
  }

  Future createIsolate() async {
    ReceivePort receivePort = ReceivePort();

    Isolate isolate =
        await Isolate.spawn(_isolateFunction, receivePort.sendPort);

    SendPort childSendPort = await receivePort.first;

    ReceivePort responsePort = ReceivePort();
    childSendPort.send(["https://randomuser.me/api/", responsePort.sendPort]);

    var response = await responsePort.first;
    print(response["results"][0]["email"]);

    isolate.kill();
  }

  static _isolateFunction(SendPort mainSendPort) async {
    ReceivePort childReceivePort = ReceivePort();
    mainSendPort.send(childReceivePort.sendPort);

    await for (var message in childReceivePort) {
      String url = message[0];
      SendPort replyPort = message[1];

      var response = await http.get(url);
      replyPort.send(jsonDecode(response.body));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(child: Container()));
  }
}
