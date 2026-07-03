import 'lib/data/models/card_database.dart';

void main() {
  for (var c in CardDatabase.pathCards) {
    if (!c.hasCenter) {
      print('${c.id}: L=${c.hasLeft}, T=${c.hasTop}, R=${c.hasRight}, B=${c.hasBottom}');
    }
  }
}


