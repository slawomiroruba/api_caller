import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Dodaj MethodChannel

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CallPhoneApp(),
    );
  }
}

class CallPhoneApp extends StatefulWidget {
  const CallPhoneApp({super.key});

  @override
  _CallPhoneAppState createState() => _CallPhoneAppState();
}

class _CallPhoneAppState extends State<CallPhoneApp> {
  static const platform =
      MethodChannel('com.example.phone/call'); // Ustawiamy kanał
  String _phoneNumber = '';
  String apiUrl = 'https://cash-online.de/caller.php';
  String _message = '';

  @override
  void initState() {
    super.initState();
    pollServerForPhoneNumber();
  }

  Future<void> pollServerForPhoneNumber() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      await getPhoneNumberFromApi();
    }
  }

  Future<void> getPhoneNumberFromApi() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String phoneNumber = data['phone'];
        if (phoneNumber.isNotEmpty && phoneNumber != _phoneNumber) {
          setState(() {
            _phoneNumber = phoneNumber;
          });
          await callPhoneNumber(phoneNumber); // Wywołujemy natywną funkcję
        }
      } else {
        setState(() {
          _message = 'Błąd w odpowiedzi z serwera: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        _message = 'Błąd: $error';
      });
    }
  }

  Future<void> callPhoneNumber(String phoneNumber) async {
    PermissionStatus status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      try {
        await platform.invokeMethod(
            'callPhone', phoneNumber); // Wywołaj natywną metodę
        await sendPostToApi(
            phoneNumber); // Wyślij POST do serwera po skutecznym połączeniu
        setState(() {
          _message = 'Połączenie z numerem $phoneNumber zakończone.';
        });
      } on PlatformException catch (e) {
        setState(() {
          _message = "Nie udało się zrealizować połączenia: '${e.message}'.";
        });
      }
    } else {
      setState(() {
        _message = 'Brak uprawnień do wykonywania połączeń telefonicznych';
      });
    }
  }

  Future<void> sendPostToApi(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({'phone': phoneNumber, 'status': 'called'}),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _message = 'Pomyślnie wysłano POST do serwera.';
        });
      } else {
        setState(() {
          _message = 'Błąd w wysyłaniu POST do serwera: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        _message = 'Błąd POST: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Caller App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _phoneNumber.isNotEmpty
                  ? 'Inicjuję połączenie: $_phoneNumber'
                  : 'Oczekiwanie na żądanie...',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
