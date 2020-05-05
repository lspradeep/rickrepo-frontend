import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rick_sanchez_bot/models/Tweet.dart';
import 'package:rick_sanchez_bot/utils/AppConstants.dart';
import 'package:rick_sanchez_bot/utils/DateUtils.dart';
import 'package:http/http.dart' as http;
import 'package:rick_sanchez_bot/main.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _selectedMenu = 0;
  int _charCount = 0;
  TextEditingController _textFieldController = TextEditingController();
  DateTime currentDate = DateTime.now();
  DateTime selectedDate = DateTime.now();
  String _selectedDateValue;
  TimeOfDay selectedTime = TimeOfDay.now();
  String _selectedTimeValue;
  dynamic userDetailsBody;
  bool _showLoading = false;
  List<Tweet> tweets = [];
  bool _showListLoading = false;

  _onChanged(String value) {
    setState(() {
      _charCount = value.length;
    });
  }

  bool _logout() {
    if (window.localStorage.containsKey("token") &&
        window.localStorage.containsKey("tokenSecret")) {
      window.localStorage['token'] = null;
      window.localStorage['tokenSecret'] = null;
      return true;
    } else {
      return false;
    }
  }

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate:
            DateTime(currentDate.year, currentDate.month, currentDate.day),
        lastDate:
            DateTime(currentDate.year, currentDate.month, currentDate.day + 7));
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _selectedDateValue = outDateFormat.format(inDateFormat.parse(
            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"));
      });
    }
  }

  _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: currentDate.hour, minute: currentDate.minute),
      builder: (BuildContext context, Widget child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        _selectedTimeValue = formatTo12Hours(DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.year,
            selectedTime.hour,
            selectedTime.minute));
      });
    }
  }

// {
// 	"date":"2020/05/03 02:55 PM",
// 	"tweetMessage":"Test Tweet4 - 2020/05/03 02:55 PM",
// 	"token":"2476831514-lCfd7SYtKh497QJf9U4Pnd1EGWUKBp8ObOfDha3",
// 	"tokenSecret":"9S64u0ZhWy8ykFoXJLIF94I3vBgNCjja91ehkQFKON2dp",
// 	"userId":"2476831514"
// }

  _getUserDetails() async {
    var userDetailsResponse = await http.get(
        "$BASE_URL/user/details?token=${window.localStorage['token']}&tokenSecret=${window.localStorage['tokenSecret']}");
    if (userDetailsResponse.statusCode == 200) {
      setState(() {
        userDetailsBody = json.decode(userDetailsResponse.body);
        _getUserFutureTweets();
      });
    } else {
      _errorToast("Error getting user details");
    }
  }

  _getUserFutureTweets() async {
    print("getUserTweets");
    setState(() {
      _showListLoading = true;
      tweets.clear();
    });
    var userTweetsResponse = await http
        .get("$BASE_URL/future-tweets?userId=${userDetailsBody["id_str"]}");
    print("getUserTweets status ${userTweetsResponse.statusCode}");

    setState(() {
      _showListLoading = false;
    });

    if (userTweetsResponse.statusCode == 200) {
      final userTweetsBody = json.decode(userTweetsResponse.body);
      print("getUserTweets bodyyy ${userTweetsBody["data"]}");
      setState(() {
        for (Map i in userTweetsBody["data"]) {
          tweets.add(Tweet.fromMap(i));
        }
      });
      print("getUserTweets tweeets ${tweets.length}");
    } else if (userTweetsResponse.statusCode == 201) {
      //empty tweets
    } else {
      _errorToast("Error getting user tweets");
    }
  }

  _postTweet() async {
    setState(() {
      _showLoading = true;
    });
    var response = await http.post(
      '$BASE_URL/schedule-tweet',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'date': "$_selectedDateValue $_selectedTimeValue",
        'tweetMessage': '${_textFieldController.text.toString()}',
        'token': '${window.localStorage['token']}',
        'tokenSecret': '${window.localStorage['tokenSecret']}',
        'userId': '${userDetailsBody["id_str"]}'
      }),
    );

    setState(() {
      _showLoading = false;
    });

    if (response.statusCode == 200) {
      _textFieldController.text = "";
      _successToast("Tweet Scheduled Successfully!");
      _getUserFutureTweets();
    } else if (response.statusCode == 400) {
      var body = json.decode(response.body);
      if (body["message"] != null) {
        _errorToast(body["message"]);
      } else {
        _errorToast("Error Scheduling tweet");
      }
    } else {
      _errorToast("Error Scheduling tweet");
    }
  }

  _updateStatus(id) async {
    setState(() {
      _showListLoading = true;
    });
    var response = await http.patch(
        "$BASE_URL/update-status?id=${id}&userId=${userDetailsBody["id_str"]}");

    if (response.statusCode == 200) {
      setState(() {
        _showListLoading = false;
      });
      _getUserFutureTweets();
      _successToast("Status Updated Successfully!");
    } else {
      _errorToast("Error updating status");
    }
  }

  // user defined function
  void _showDialog(id) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Cancel Scheduled Tweet"),
          content: new Text("Do you want to cancel this schedule tweet ?"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("Yes"),
              onPressed: () {
                _updateStatus(id);
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Logout"),
          content: new Text("Are you sure want to logout ?"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("Yes"),
              onPressed: () {
                Navigator.of(context).pop();
                if (_logout()) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                }
              },
            )
          ],
        );
      },
    );
  }

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

  @override
  void initState() {
    super.initState();
    _selectedDateValue = outDateFormat.format(inDateFormat.parse(
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"));
    _selectedTimeValue = formatTo12Hours(DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.year,
        selectedTime.hour,
        selectedTime.minute));

    //Api calls
    _getUserDetails();
  }

  _validatePostMessage() {
    if (_charCount == 0) {
      _errorToast("Tweet message can't be empty.");
      return false;
    }
    if (_charCount > 280) {
      _errorToast("Tweet message can't be empty.");
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Column(
          children: <Widget>[
            _tabletNav(context),
            Flexible(
              flex: 1,
              child: Row(
                children: <Widget>[
                  Flexible(
                      flex: 6,
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(children: [
                            Stack(children: [
                              Container(
                                color: Colors.blue,
                                height: 150,
                              ),
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                          width: 100,
                                          height: 100,
                                          decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: new DecorationImage(
                                                  fit: BoxFit.fill,
                                                  image: (userDetailsBody ==
                                                          null)
                                                      ? NetworkImage(
                                                          "https://p.kindpng.com/picc/s/220-2201160_line-clipart-computer-icons-social-media-facebook-small.png")
                                                      : new NetworkImage(
                                                          userDetailsBody["profile_image_url"])))),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                (userDetailsBody == null)
                                                    ? "User Name"
                                                    : userDetailsBody["name"],
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                    fontSize: 25,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                  (userDetailsBody == null)
                                                      ? "User Bio"
                                                      : userDetailsBody[
                                                          "description"],
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                  ))
                                            ]),
                                      )
                                    ]),
                              )
                            ]),
                            SizedBox(height: 10),
                            Text(
                              "Future Tweets",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.blue),
                            ),
                            SizedBox(height: 20),
                            _showListLoading
                                ? CircularProgressIndicator(
                                    backgroundColor: Colors.cyan,
                                    strokeWidth: 5,
                                  )
                                : (tweets.length == 0)
                                    ? Text(
                                        "It's Empty.\nYour scheduled tweets will appear here.",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.blue.shade900),
                                      )
                                    : Flexible(
                                        child: ListView.builder(
                                          itemCount: tweets.length,
                                          itemBuilder: (context, index) {
                                            return Column(
                                              children: <Widget>[
                                                ListTile(
                                                  title: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Text(
                                                            tweets[index]
                                                                .tweetMessage),
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Text(
                                                      tweets[index].dateStr),
                                                  trailing: tweets[index]
                                                          .cancelled
                                                      ? Container(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 4,
                                                                  right: 4),
                                                          decoration:
                                                              new BoxDecoration(
                                                                  color: Colors
                                                                      .red),
                                                          child: Text(
                                                              "CANCELLED",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              )),
                                                        )
                                                      : IconButton(
                                                          icon: Icon(
                                                              Icons.cancel),
                                                          onPressed: () {
                                                            _showDialog(
                                                                tweets[index]
                                                                    .id);
                                                          }),
                                                ),
                                                Divider(
                                                  color: Colors.grey,
                                                )
                                              ],
                                            );
                                          },
                                        ),
                                      )
                          ]),
                        ),
                      )),
                  Flexible(
                      flex: 4,
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(children: [
                            Container(
                                height: 160,
                                child: Expanded(
                                  child: TextFormField(
                                    controller: _textFieldController,
                                    onChanged: _onChanged,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 5,
                                    decoration: new InputDecoration(
                                      counter:
                                          Text("${_charCount.toString()}/280"),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 10),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.blue, width: 1.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.blue, width: 1.0),
                                      ),
                                      hintText: 'Your Tweet Message!',
                                      errorText: (_charCount > 280)
                                          ? "Tweet Message cannot contain \n more than 280 characters."
                                          : null,
                                    ),
                                  ),
                                )),
                            SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                _selectDate(context);
                              },
                              child: Container(
                                color: Colors.blue.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(children: [
                                    Text("Pick Date"),
                                    SizedBox(width: 20),
                                    Icon(Icons.date_range),
                                    SizedBox(width: 30),
                                    Text(
                                      _selectedDateValue,
                                      style: TextStyle(color: Colors.blue),
                                    )
                                  ]),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                _selectTime(context);
                              },
                              child: Container(
                                color: Colors.blue.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(children: [
                                    Text("Pick Time"),
                                    SizedBox(width: 20),
                                    Icon(Icons.timer),
                                    SizedBox(width: 30),
                                    Text(
                                      _selectedTimeValue,
                                      style: TextStyle(color: Colors.blue),
                                    )
                                  ]),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            _showLoading
                                ? CircularProgressIndicator(
                                    backgroundColor: Colors.cyan,
                                    strokeWidth: 5,
                                  )
                                : RaisedButton(
                                    color: Colors.blue,
                                    onPressed: () {
                                      if (_validatePostMessage()) {
                                        _postTweet();
                                      }
                                    },
                                    child: Text(
                                      "Schedule Tweet",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                          ]),
                        ),
                      ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabletNav(BuildContext context) {
    return Container(
      color: Colors.blue,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.only(left: 40, right: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              (_selectedMenu == 0) ? "RICK BOT" : "",
              style: TextStyle(
                  fontSize: 20,
                  color: _selectedMenu == 0 ? Colors.white : Colors.black),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GestureDetector(
                  child: Text(
                    "Home",
                    style: TextStyle(
                        fontSize: 20,
                        color:
                            _selectedMenu == 0 ? Colors.white : Colors.black),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedMenu = 0;
                    });
                  },
                ),
                SizedBox(width: 30),
                GestureDetector(
                  child: Text(
                    "About Us",
                    style: TextStyle(
                        fontSize: 20,
                        color:
                            _selectedMenu == 1 ? Colors.white : Colors.black),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedMenu = 1;
                    });
                  },
                ),
                SizedBox(width: 30),
                GestureDetector(
                  child: Text(
                    "Contact",
                    style: TextStyle(
                        fontSize: 20,
                        color:
                            _selectedMenu == 2 ? Colors.white : Colors.black),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedMenu = 2;
                    });
                  },
                ),
                SizedBox(width: 30),
                GestureDetector(
                  child: Text(
                    "Logout",
                    style: TextStyle(
                        fontSize: 20,
                        color:
                            _selectedMenu == 3 ? Colors.white : Colors.black),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedMenu = 3;
                    });
                    _showLogoutDialog();
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
