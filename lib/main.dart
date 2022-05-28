import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_security_systems/history.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late DatabaseReference _dbRef;
  bool _securityStatus = false;

  _updateValue(bool status) {
    _dbRef.update({"security_status": status});
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _dbRef = FirebaseDatabase.instance.reference();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Main Door"),
      //   centerTitle: true,
      //   backgroundColor: Colors.teal,
      // ),
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Security Status"),
                        StreamBuilder(
                          stream: _dbRef.onValue,
                          builder: (context, AsyncSnapshot snap) {
                            if (snap.hasData &&
                                !snap.hasError &&
                                snap.data.snapshot.value != null) {
                              var data = snap.data.snapshot.value;
                              _securityStatus = data['security_status'];
                              return CupertinoSwitch(
                                value: _securityStatus,
                                onChanged: (value) {
                                  _updateValue(value);
                                },
                              );
                            } else {
                              return CupertinoSwitch(
                                value: false,
                                onChanged: (value) {},
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Lottie.asset(
                    'assets/door-open.json',
                    controller: _controller,
                    onLoaded: (composition) {
                      _controller.duration = composition.duration;
                    },
                  ),
                  StreamBuilder(
                    stream: _dbRef.onValue,
                    builder: (context, AsyncSnapshot snap) {
                      if (snap.hasData &&
                          !snap.hasError &&
                          snap.data.snapshot.value != null) {
                        var data = snap.data.snapshot.value;
                        _securityStatus = data['security_status'];
                        if (data['door_status']) {
                          _controller.forward();
                        } else {
                          _controller.reverse();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Door Status: ${data['door_status'] ? "Open" : "Closed"}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        );
                      } else {
                        return const Center(child: Text("No data"));
                      }
                    },
                  ),
                  const Spacer(),
                  const Spacer(),
                ],
              ),
              SlidingUpPanel(
                renderPanelSheet: false,
                panel: _floatingPanel("test"),
                collapsed: _floatingCollapsed(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingCollapsed() {
    return Container(
      decoration: const BoxDecoration(
          // color: Colors.transparent,
          ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            RotatedBox(
              quarterTurns: 3,
              child: Icon(
                Icons.double_arrow_sharp,
                color: Colors.white,
              ),
            ),
            Text(
              "Swipe up to details",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _floatingPanel(String description) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.only(top: 100,
        left: 10,
        right: 10,
        bottom: 10
      ),
      child: Center(
        child: StreamBuilder(
          stream: _dbRef.onValue,
          builder: (context, AsyncSnapshot snap) {
            if (snap.hasData &&
                !snap.hasError &&
                snap.data.snapshot.value != null) {
              var data = snap.data.snapshot.value;
              // print(json.encode(data));
              _securityStatus = data['security_status'];
              if (data['door_status']) {
                _controller.forward();
              } else {
                _controller.reverse();
              }

              var list = historyFromJson(json.encode(data['history']));
              List<History> keys = list.values.toList();

              keys.sort((b, a) => a.timestamp.compareTo(b.timestamp));

              return ListView.builder(
                itemCount: keys.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, i) {
                  return ListTile(
                    title: Text(
                        DateFormat('yyyy-MM-dd – kk:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(
                            keys[i].timestamp * 1000)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      keys[i].doorStatus == 1 ? "Open" : "Close",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              );
            } else {
              return const Center(child: Text("No data"));
            }
          },
        ),
      ),
    );
  }
}
