import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rick_sanchez_bot/utils/AppConstants.dart';
import 'package:rick_sanchez_bot/utils/DateUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTweet extends StatefulWidget {
  final String userId;
  // In the constructor, require a Todo.
  AddTweet({Key key, @required this.userId}) : super(key: key);

  @override
  _AddTweetState createState() => _AddTweetState();
}

class _AddTweetState extends State<AddTweet> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Dio dio = new Dio();
  TextEditingController _textFieldController = TextEditingController();
  int _charCount = 0;
  DateTime currentDate = DateTime.now();
  DateTime selectedDate = DateTime.now();
  String _selectedDateValue;
  TimeOfDay selectedTime = TimeOfDay.now();
  String _selectedTimeValue;
  bool _showLoading = false;

  _onChanged(String value) {
    setState(() {
      _charCount = value.length;
    });
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

  _postTweet() async {
    setState(() {
      _showLoading = true;
    });

    _prefs.then((SharedPreferences prefs) async {
      var response = await dio.post(
        '$BASE_URL/schedule-tweet',
        data: {
          'date': "$_selectedDateValue $_selectedTimeValue",
          'tweetMessage': '${_textFieldController.text.toString()}',
          'token': '${prefs.getString('token')}',
          'tokenSecret': '${prefs.getString('tokenSecret')}',
          'userId': widget.userId
        },
      );

      setState(() {
        _showLoading = false;
      });

      if (response.statusCode == 200) {
        _textFieldController.text = "";
        _successToast("Tweet Scheduled Successfully!");
        Navigator.of(context).pop(true);
      } else if (response.statusCode == 201) {
        var body = response.data;
        if (body["message"] != null) {
          _errorToast(body["message"]);
        } else {
          _errorToast("Error Scheduling tweet");
        }
      } else {
        _errorToast("Error Scheduling tweet");
      }
    });
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule Tweet"),
      ),
      body: _screenTwoForMobile(context),
    );
  }

  _screenTwoForMobile(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Container(
              height: 150,
                child: Expanded(
                  child: TextFormField(
                    controller: _textFieldController,
                    onChanged: _onChanged,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    decoration: new InputDecoration(
                      counter: Text("${_charCount.toString()}/280"),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 5),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 1.0),
                      ),
                      hintText: 'Your Tweet Message!',
                      errorText: (_charCount > 280)
                          ? "Tweet Message cannot contain \n more than 280 characters."
                          : null,
                    ),
                  ),
                )),
            SizedBox(height: 16),
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
                    SizedBox(width: 8),
                    Icon(Icons.date_range),
                    SizedBox(width: 16),
                    Text(
                      _selectedDateValue,
                      style: TextStyle(color: Colors.blue),
                    )
                  ]),
                ),
              ),
            ),
            SizedBox(height: 16),
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
                    SizedBox(width: 8),
                    Icon(Icons.timer),
                    SizedBox(width: 16),
                    Text(
                      _selectedTimeValue,
                      style: TextStyle(color: Colors.blue),
                    )
                  ]),
                ),
              ),
            ),
            SizedBox(
              height: 32,
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
      ),
    );
  }
}
