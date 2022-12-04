import 'item.dart';

enum ItemCategory {
  medicine('Medicine'),
  balls('Balls');

  const ItemCategory(this.name);
  final String name;
}


class ItemSlot {
  ItemSlot(this.item, this.quantity);

  Item item;
  int quantity;
}

typedef ItemPocket = List<ItemSlot>;

class Bag {
  final Map<ItemCategory, ItemPocket> pockets = {};

  int quantityOf(Item item) {
    final pocket = pockets[item.pocket];
    if (pocket == null) {
      return 0;
    }
    for (final slot in pocket) {
      if (slot.item == item) {
        return slot.quantity;
      }
    }
    return 0;
  }

  void give(Item item, int quantity) {
    if (!pockets.containsKey(item.pocket)) {
      pockets[item.pocket] = [ItemSlot(item, quantity)];
      return;
    }
    final pocket = pockets[item.pocket]!;
    for (final slot in pocket) {
      if (slot.item == item) {
        slot.quantity += quantity;
        return;
      }
    }
    pocket.add(ItemSlot(item, quantity));
  }

  bool take(Item item, int quantity) {
    if (quantityOf(item) < quantity) {
      return false;
    }
    final pocket = pockets[item.pocket]!;
    bool remove = false;
    for (final slot in pocket) {
      if (slot.item == item && slot.quantity >= quantity) {
        slot.quantity -= quantity;
        remove = slot.quantity == 0;
        break;
      }
    }
    if (remove) {
      pocket.removeWhere((slot) => slot.item == item);
    }
    return remove || quantityOf(item) > 0;
  }
}
