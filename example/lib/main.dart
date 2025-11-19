import 'package:flutter/material.dart';
import 'package:s_toggle/s_toggle.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 's_toggle Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _toggleValue = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('s_toggle Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Toggle the switch:',
            ),
            const SizedBox(height: 20),
            SToggle(
              size: 80.0,
              onColor: Colors.green,
              offColor: Colors.red,
              value: _toggleValue,
              onChange: (value) {
                setState(() {
                  _toggleValue = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Toggle is ${_toggleValue ? 'ON' : 'OFF'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
