/// The rider who signed in through `POST /api/rider/login` on the Nuvora site.
///
/// Only the fields the website returns are kept here. When the rider app is
/// connected to the full Nuvora API later, the same session object can be
/// filled from the assignments and profile endpoints instead.
class RiderSession {
  RiderSession._();

  static final RiderSession instance = RiderSession._();

  int? id;
  String name = 'Nuvora Rider';
  String email = '';
  String vehicle = 'Motorcycle';
  String area = '';
  String station = '';

  bool get isSignedIn => id != null;

  /// Reads the `rider` object from a successful login response.
  void adopt(Map<String, dynamic> payload) {
    final rider = payload['rider'];
    final data = rider is Map ? Map<String, dynamic>.from(rider) : payload;

    id = int.tryParse('${data['id'] ?? ''}') ?? id;
    name = _text(data['name']) ?? name;
    email = _text(data['email']) ?? email;
    vehicle = _text(data['vehicle']) ?? vehicle;
    area = _text(data['area']) ?? area;
    station = _text(data['station']) ?? station;
  }

  void clear() {
    id = null;
    name = 'Nuvora Rider';
    email = '';
    vehicle = 'Motorcycle';
    area = '';
    station = '';
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
