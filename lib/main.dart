import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:rick_sanchez_bot/ui/homescreen.dart';
import 'package:rick_sanchez_bot/utils/AppConstants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';


void main() {
  runApp(new MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Rick Bot',
    theme: ThemeData(
      fontFamily: "Montserrat",
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: LoginScreen(),
  ));
}

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Timer timer;
  var temperoryCredsBody;
  var callbackUrlResponseBody;
  bool _showLoading = true;
  Dio dio = new Dio();
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  _successToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  _errorToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void _loginCompleted() {
    print("_loginCompleted");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }

  void _launchURL(String urlToLaunch) async {
    var url = urlToLaunch;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _errorToast("Could not launch url.");
      throw 'Could not launch $url';
    }
  }

  //Step 3: POST oauth/access_token
  void getFinalAuthToken() async {
    if (temperoryCredsBody != null &&
        callbackUrlResponseBody != null &&
        temperoryCredsBody["oauth_token"] != null &&
        temperoryCredsBody["oauth_token_secret"] != null &&
        callbackUrlResponseBody["oauth_token"] != null &&
        callbackUrlResponseBody["oauth_verifier"] != null &&
        (temperoryCredsBody["oauth_token"] ==
            callbackUrlResponseBody["oauth_token"])) {
      print("getFinalAuthToken 2");
      Response finalTokenResponse = await dio.get(
          "$BASE_URL/rick-sanchez/access-token?oauth_token=${callbackUrlResponseBody["oauth_token"]}&oauth_verifier=${callbackUrlResponseBody["oauth_verifier"]}&oauth_token_secret=${temperoryCredsBody["oauth_token_secret"]}");
      var finalTokenResponseBody = finalTokenResponse.data;

      if (finalTokenResponseBody["final_credentials"]["token"] != null &&
          finalTokenResponseBody["final_credentials"]["tokenSecret"] != null) {
        _prefs.then((SharedPreferences prefs) {
          prefs.setString(
              'token', finalTokenResponseBody["final_credentials"]["token"]);
          prefs.setString('tokenSecret',
              finalTokenResponseBody["final_credentials"]["tokenSecret"]);
          _successToast("Login Successful");
          _loginCompleted();
        });
      }
      setState(() {
        _showLoading = false;
      });
      print("getFinalAuthToken 3");
      print("finalTokenResponse response is $finalTokenResponseBody");
    }
  }

  // Step 2: GET oauth/authorize
  void waitForCallbackurlResponse() async {
    print("waitForCallbackurlResponse 1");
    final callbackUrlResponse =
        await dio.get("$BASE_URL/rick-sanchez/twitter/callback_url/response");
    print("waitForCallbackurlResponse 2");
    if (callbackUrlResponse.statusCode == 200 &&
        (callbackUrlResponse.data["oauth_token"] ==
            temperoryCredsBody["oauth_token"])) {
      timer?.cancel();
      callbackUrlResponseBody = callbackUrlResponse.data;

      if (temperoryCredsBody != null &&
          callbackUrlResponseBody != null &&
          temperoryCredsBody["oauth_token"] != null &&
          temperoryCredsBody["oauth_token_secret"] != null &&
          callbackUrlResponseBody["oauth_token"] != null &&
          callbackUrlResponseBody["oauth_verifier"] != null &&
          (temperoryCredsBody["oauth_token"] ==
              callbackUrlResponseBody["oauth_token"])) {
        print("getFinalAuthToken 1");
        getFinalAuthToken();
      }
    }
  }

  // Step 1: POST oauth/request_token
  void getRequestTokenAndTokenSecret() async {
    print("getRequestTokenAndTokenSecret1");

    setState(() {
      _showLoading = true;
    });
    final temperoryCreds =
        await dio.get("$BASE_URL/rick-sanchez/oauthverifier");

    print("getRequestTokenAndTokenSecret2 ${temperoryCreds.data}");
    if (temperoryCreds.statusCode == 200) {
      temperoryCredsBody = temperoryCreds.data;
      String urlToLaunch =
          "https://api.twitter.com/oauth/authorize?oauth_token=${temperoryCredsBody["oauth_token"]}";

      print("urlToLaunch is $urlToLaunch");

      // final result = await Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //       builder: (context) => WebViewWdgt(urlToOpen: urlToLaunch)),
      // );
      _launchURL(urlToLaunch);
      timer = Timer.periodic(
          Duration(seconds: 8), (Timer t) => waitForCallbackurlResponse());

      //  }
    } else {
      setState(() {
        _showLoading = false;
      });
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    _prefs.then((SharedPreferences prefs) {
      if ((prefs.containsKey("token") && prefs.containsKey("tokenSecret")) &&
          (prefs.getString('token') != null &&
              prefs.getString('tokenSecret') != null) &&
          (prefs.getString('token').length > 5 &&
              prefs.getString('tokenSecret').length > 5)) {
        setState(() {
          _showLoading = false;
        });
        _loginCompleted();
      } else {
        setState(() {
          _showLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rick Sanchez (Twitter Bot)'),
      ),
      body: ScreenTypeLayout(
        desktop: _getDesktopView(),
        mobile: _getDesktopView(),
      ),
    );
  }

  Widget _getDesktopView() {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage("images/rickbg.jpg"),
        fit: BoxFit.cover,
      )),
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black38.withOpacity(0.5),
                Colors.black87.withOpacity(0.5)
              ]),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(""),
              SizedBox(height: 20),
              _showLoading
                  ? CircularProgressIndicator(
                      backgroundColor: Colors.cyan,
                      strokeWidth: 5,
                    )
                  : RaisedButton.icon(
                      color: Colors.blue.shade700,
                      onPressed: () {
                        getRequestTokenAndTokenSecret();
                      },
                      icon: Icon(
                        Icons.email,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Authenticate",
                        style: TextStyle(color: Colors.white),
                      )),
              SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );
  }
}
