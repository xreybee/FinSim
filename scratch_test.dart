import 'dart:convert';

void main() {
  final Map<String, dynamic> goalsJson = {};
  goalsJson['uid1'] = [
    {
      'id': '1',
      'name': 'Goal 1'
    }
  ];
  
  String encoded = jsonEncode(goalsJson);
  print('Encoded: $encoded');
  
  Map<String, dynamic> decoded = jsonDecode(encoded);
  decoded.forEach((key, val) {
    print('Key: $key, Val Type: ${val.runtimeType}');
    final List<dynamic> list = val;
    print('List Length: ${list.length}');
  });
}
