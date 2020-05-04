import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:rick_sanchez_bot/utils/AppConstants.dart';



class WebViewWdgt extends StatefulWidget {
  final String urlToOpen;
  // In the constructor, require a Todo.
  WebViewWdgt({Key key, @required this.urlToOpen}) : super(key: key);

  @override
  _WebViewWdgtState createState() => _WebViewWdgtState();
}

class _WebViewWdgtState extends State<WebViewWdgt> {
  // Instance of WebView plugin
   final flutterWebViewPlugin = FlutterWebviewPlugin();

  // On urlChanged stream
  StreamSubscription<String> _onUrlChanged;
  String msg = "";
  String link = "";

  @override
  void initState() {
    super.initState();
    //Add a listener to on url changed
    _onUrlChanged = flutterWebViewPlugin.onUrlChanged.listen((String url) {
      if (mounted) {
        // setState(() {
        //   _history.add('onUrlChanged: $url');
        //   Navigator.pop(context, '$url');
        // });
        if(url.contains(TWITTER_CALLBACK_URL)){
           Navigator.pop(context, '$url');
        }
      }
    });

    setState(() {
      msg = "Waiting to open ${widget.urlToOpen}.....";
      link = widget.urlToOpen;
    });
  }

  @override
  void dispose() {
    _onUrlChanged.cancel();
    flutterWebViewPlugin.dispose();
    super.dispose();
  }

  final Set<JavascriptChannel> jsChannels = [
    JavascriptChannel(
        name: 'Print',
        onMessageReceived: (JavascriptMessage message) {
          print(message.message);
        }),
  ].toSet();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       routes: {
        "/": (_) => new WebviewScaffold(
          url: "$link",
          appBar: new AppBar(
            title: new Text("$link Twitter Access Required"),
          ),
        ),
      },
    );
  }
}
