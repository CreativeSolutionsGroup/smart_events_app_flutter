
class Strings {

  static String displayDate(DateTime date){
    if(date == null)return "ERROR";

    DateTime now = DateTime.now();
    int month = date.month;
    int day = date.day;
    int hour = date.hour;
    int min = date.minute;
    bool pm = hour > 11;

    String finalStr = "";

    if(now.month != month || now.day != day){
      finalStr += '${month}/${day} ';
    }
    String hourStr = hour == 0 ? "12" : '${hour % 12}';
    finalStr += hourStr + ':${(min < 10 ? '0' : "")}${min} ${pm ? "PM" : "AM"}';
    return finalStr;
  }
}