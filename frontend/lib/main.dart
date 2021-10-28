import 'dart:convert';
import 'dart:io';
import 'package:after_layout/after_layout.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Assistant',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: Splash(),
    );
  }
}

class Splash extends StatefulWidget {
  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> with AfterLayoutMixin<Splash> {
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      Navigator.of(context).pushReplacement(
          new MaterialPageRoute(builder: (context) => MyHomePage()));
    } else {
      await prefs.setBool('seen', true);
      Navigator.of(context).pushReplacement(
          new MaterialPageRoute(builder: (context) => FormScreen()));
    }
  }

  @override
  void afterFirstLayout(BuildContext context) => checkFirstSeen();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Text('Loading...'),
      ),
    );
  }
}

class FormScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return FormScreenState();
  }
}

class FormScreenState extends State<FormScreen> {
  String _name;
  String _email;
  String _address;
  String _emcontact1;
  String _emcontact2;
  String _age;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Widget _buildName() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Name'),
      maxLength: 10,
      validator: (String value) {
        if (value.isEmpty) {
          return 'Name is Required';
        }

        return null;
      },
      onSaved: (String value) {
        _name = value;
      },
    );
  }

  Widget _buildEmail() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Email'),
      validator: (String value) {
        if (value.isEmpty) {
          return 'Email is Required';
        }

        if (!RegExp(
                r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
            .hasMatch(value)) {
          return 'Please enter a valid email Address';
        }

        return null;
      },
      onSaved: (String value) {
        _email = value;
      },
    );
  }

  Widget _buildAddress() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Address'),
      validator: (String value) {
        if (value.isEmpty) {
          return 'Address is Required';
        }

        return null;
      },
      onSaved: (String value) {
        _address = value;
      },
    );
  }

  Widget _buildEmc1() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Emergency Contact 1'),
      keyboardType: TextInputType.phone,
      validator: (String value) {
        if (value.isEmpty) {
          return 'Emergency Contact is Required';
        }

        return null;
      },
      onSaved: (String value) {
        _emcontact1 = value;
      },
    );
  }

  Widget _buildEmc2() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Emergency Contact 2'),
      keyboardType: TextInputType.phone,
      validator: (String value) {
        if (value.isEmpty) {
          return 'Emergency Contact is Required';
        }

        return null;
      },
      onSaved: (String value) {
        _emcontact2 = value;
      },
    );
  }

  Widget _buildAge() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Age'),
      keyboardType: TextInputType.number,
      validator: (String value) {
        int calories = int.tryParse(value);

        if (calories == null || calories <= 0) {
          return 'Age must be greater than 0';
        }

        return null;
      },
      onSaved: (String value) {
        _age = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildName(),
                _buildEmail(),
                _buildAddress(),
                _buildEmc1(),
                _buildEmc2(),
                _buildAge(),
                SizedBox(height: 100),
                // ignore: deprecated_member_use
                RaisedButton(
                  child: Text(
                    'Submit',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState.validate()) {
                      return;
                    }

                    _formKey.currentState.save();
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();

                    await prefs.setString('name', _name);
                    await prefs.setString('email', _email);
                    await prefs.setString('address', _address);
                    await prefs.setString('emcontact1', _emcontact1);
                    await prefs.setString('emcontact2', _emcontact2);
                    await prefs.setInt('age', int.tryParse(_age));
                    print(_name);
                    print(_email);
                    print(_address);
                    print(_emcontact1);
                    print(_emcontact2);
                    print(_age);

                    //Send to API
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<String> _data = [];
  static const String BOT_URL =
      "https://memory-assistant.herokuapp.com/query"; // replace with server address
  TextEditingController _queryController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Memory Assistant"),
      ),
      body: Stack(
        children: <Widget>[
          AnimatedList(
              // key to call remove and insert from anywhere
              key: _listKey,
              initialItemCount: _data.length,
              itemBuilder:
                  (BuildContext context, int index, Animation animation) {
                return _buildItem(_data[index], animation, index);
              }),
          Align(
            alignment: Alignment.bottomCenter,
            child: TextField(
              decoration: InputDecoration(
                icon: Icon(
                  Icons.message,
                  color: Colors.greenAccent,
                ),
                hintText: "Hello",
              ),
              controller: _queryController,
              textInputAction: TextInputAction.send,
              onSubmitted: (msg) {
                this._getResponse();
              },
            ),
          )
        ],
      ),
    );
  }

  http.Client _getClient() {
    return http.Client();
  }

  Future<void> _getResponse() async {
    if (_queryController.text.length > 0) {
      this._insertSingleItem(_queryController.text);
      var client = _getClient();
      try {
        print(_queryController.text);
        var response = await client.post(
          BOT_URL,
          body: {"query": _queryController.text},
        );
        print(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (data['response'] == "Your name is") {
          String name = prefs.getString('name');
          String botResponse = data['response'] + " $name";
          print(botResponse);
          _insertSingleItem(botResponse + "<bot>");
        } else if (data['response'] == "You live in") {
          String address = prefs.getString('address');
          String botResponse = data['response'] + " $address";
          _insertSingleItem(botResponse + "<bot>");
        } else if (data['response'] == "Here are some emergency contacts :-") {
          String ec1 = prefs.getString('emcontact1');
          String ec2 = prefs.getString('emcontact2');
          String botResponse = data['response'] +
              "\nEmergency contact 1 :- $ec1 \nEmergency contact 2 :- $ec2 \nDoctor contact :- 8976540321 \nPolice contact :- 100 \n Ambulance contact :- 102";
          _insertSingleItem(botResponse + "<bot>");
        } else if (data['response'] == "Opening Google Maps for directions") {
          _insertSingleItem(data['response'] + "<bot>");
          // ignore: await_only_futures
          await _openMap();
        } else if (data['response'] == "") {
          String botResponse = data['response'] +
              "Sorry, I did not understand you. Please type again";
          _insertSingleItem(botResponse + "<bot>");
        } else {
          _insertSingleItem(data['response'] + "<bot>");
        }
      } catch (e) {
        print("Failed -> $e");
      } finally {
        client.close();
        _queryController.clear();
      }
    }
  }

  void _insertSingleItem(String message) {
    //File f = new File('E:\\conversations.txt');
    //f.writeAsStringSync(message, mode: FileMode.append);
    _data.add(message);
    _listKey.currentState.insertItem(_data.length - 1);
  }

  void _openMap() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String address = prefs.getString('address');
    String url =
        'https://www.google.com/maps/dir/?api=1&destination=$address&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildItem(String item, Animation animation, int index) {
    bool mine = item.endsWith("<bot>");
    return SizeTransition(
        sizeFactor: animation,
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child: Container(
              alignment: mine ? Alignment.topLeft : Alignment.topRight,
              child: Bubble(
                child: Text(item.replaceAll("<bot>", "")),
                color: mine ? Colors.amber[100] : Colors.cyan[100],
                padding: BubbleEdges.all(10),
              )),
        ));
  }
}
