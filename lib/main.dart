import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PostOffice {
  final String name;
  final String branchType;

  PostOffice({required this.name, required this.branchType});

  factory PostOffice.fromJson(Map<String, dynamic> json) {
    return PostOffice(
      name: json['Name'],
      branchType: json['BranchType'],
    );
  }
}

class PincodeData {
  final List<PostOffice> postOffices;

  PincodeData({required this.postOffices});

  factory PincodeData.fromJson(List<dynamic> json) {
    List<PostOffice> postOffices = [];
    for (var office in json) {
      postOffices.add(PostOffice.fromJson(office));
    }
    return PincodeData(postOffices: postOffices);
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pincode Search by Varad',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(title: 'Pincode Search by Varad'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _pincodeController = TextEditingController();
  String _pincode = '';
  PincodeData? _pincodeData;
  bool _isLoading = false;

  Future<void> fetchData(String pincode) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://api.postalpincode.in/pincode/$pincode');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData is List && decodedData.isNotEmpty) {
          final postOfficeData = decodedData[0]['PostOffice'];

          if (postOfficeData != null && postOfficeData.isNotEmpty) {
            final pincodeData = PincodeData.fromJson(postOfficeData);

            setState(() {
              _pincodeData = pincodeData;
              _isLoading = false;
            });
          } else {
            setState(() {
              _pincodeData = null;
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _pincodeData = null;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _pincodeData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _pincodeData = null;
        _isLoading = false;
      });
      print('An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pincodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter a pincode',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _pincode = _pincodeController.text;
                          });
                          fetchData(_pincode);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            CircularProgressIndicator()
          else if (_pincodeData != null)
            Expanded(
              child: ListView.builder(
                itemCount: _pincodeData!.postOffices.length,
                itemBuilder: (context, index) {
                  final postOffice = _pincodeData!.postOffices[index];
                  return ListTile(
                    title: Text(postOffice.name),
                    subtitle: Text(postOffice.branchType),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
