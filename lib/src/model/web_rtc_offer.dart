class WebRtcOffer {
  const WebRtcOffer({
    required this.offer,
  });

  static const kType = 'offer';

  final Map<String, dynamic> offer;

  String get type => kType;

  static WebRtcOffer fromDynamic(dynamic map) {
    if (map == null) {
      throw Exception('[$kType]: map is null');
    }

    return WebRtcOffer(offer: Map<String, dynamic>.from(map['offer']));
  }

  Map<String, dynamic> toJson() => {
        'offer': offer,
        'type': kType,
      };
}
