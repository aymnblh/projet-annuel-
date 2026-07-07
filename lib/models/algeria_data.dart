import 'dart:convert';
import 'package:flutter/services.dart';

class AlgeriaData {
  static List<dynamic> _wilayas = [];
  static List<dynamic> _communes = [];

  static Future<void> loadData() async {
    if (_wilayas.isNotEmpty) return;
    try {
      final String wStr = await rootBundle.loadString('assets/wilayas.json');
      _wilayas = json.decode(wStr);
      final String cStr = await rootBundle.loadString('assets/communes.json');
      _communes = json.decode(cStr);
    } catch (e) {
      print("Erreur JSON: $e");
    }
  }

  static List<String> getWilayas() {
    List<String> list = [];
    for (int i = 0; i < _wilayas.length; i++) {
      int code = i + 1;
      String name = _wilayas[i]['nom_fr'];
      String codeStr = code < 10 ? "0$code" : "$code";
      list.add("$codeStr - $name");
    }
    return list;
  }

  static List<String> getCommunes(String fullWilayaName) {
    if (_communes.isEmpty) return [];
    try {
      int targetId = int.parse(fullWilayaName.split(' - ')[0]);
      var filtered = _communes.where((c) => c['id_wilaya'] == targetId).toList();
      List<String> names = filtered.map<String>((c) => c['nom_fr'] as String).toList();
      names.sort();
      return names;
    } catch (e) {
      return [];
    }
  }
}