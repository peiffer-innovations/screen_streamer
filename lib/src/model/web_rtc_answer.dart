class WebRtcAnswer {
  const WebRtcAnswer({
    required this.answer,
    required this.candidates,
  });

  static const kType = 'answer';

  final Map<String, dynamic> answer;
  final List<Map<String, dynamic>> candidates;

  String get type => kType;

  static WebRtcAnswer fromDynamic(dynamic map) {
    if (map == null) {
      throw Exception('[$kType]: map is null');
    }

    return WebRtcAnswer(
      answer: Map<String, dynamic>.from(map['answer']),
      candidates: List<Map<String, dynamic>>.from(map['candidates']),
    );
  }

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'candidates': candidates,
        'type': kType,
      };
}
