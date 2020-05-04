import 'package:intl/intl.dart';

DateTime now = DateTime.now();
DateFormat outDateFormat = DateFormat('yyyy/MM/dd');
DateFormat inDateFormat = DateFormat('d/M/yyyy');
DateFormat time12Format = DateFormat('hh:mm a');

formatTo12Hours(DateTime dateTime){
  return time12Format.format(dateTime);
}