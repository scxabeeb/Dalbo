import 'package:flutter/material.dart';
import 'api.dart';

class AppBrand {
  final Map<String, dynamic> data;
  AppBrand([this.data = const {}]);
  String get name => data['appName'] ?? 'CTC DALBO';
  String get tagline => data['tagline'] ?? 'Adeegga aad rabto, halka aad joogto.';
  String get city => data['city'] ?? 'Garowe';
  String get heroTitle => data['heroTitle'] ?? 'Maxaad u baahan tahay maanta?';
  String get heroDescription =>
      data['heroDescription'] ?? 'Farsamoyaqaan albaabkaaga kuugu yimaada.';
  String get currency => data['currency'] ?? 'USD';
  bool get registrationEnabled => data['registrationEnabled'] ?? true;
  bool get productsEnabled => data['productsEnabled'] ?? true;
  String? get logoUrl => data['logoUrl'];
  Color color(String key, int fallback) {
    final value = data[key];
    return value is String && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)
        ? Color(0xff000000 | int.parse(value.substring(1), radix: 16))
        : Color(fallback);
  }

  Color get primary => color('primaryColor', 0xff0e305d);
  Color get accent => color('accentColor', 0xffff6b0b);
}

final appBrand = ValueNotifier(AppBrand());
Future<void> refreshBrand() async {
  try {
    appBrand.value = AppBrand(
      Map<String, dynamic>.from(await api.request('/settings')),
    );
  } catch (_) {
    /* Keep the last available brand while offline. */
  }
}
