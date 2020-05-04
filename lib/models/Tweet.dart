class Tweet {
  String id;
  String tweetMessage;
  String dateStr;
  bool cancelled;

  Tweet(this.id, this.tweetMessage, this.dateStr, this.cancelled);

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      '_id': id,
      'tweetMessage': tweetMessage,
      'dateStr': dateStr,
      'cancelled': cancelled
    };
    return map;
  }

  Tweet.fromMap(Map<String, dynamic> map) {
    id = map['_id'];
    tweetMessage = map['tweetMessage'];
    dateStr = map['dateStr'];
    cancelled = map['cancelled'];
  }
}
