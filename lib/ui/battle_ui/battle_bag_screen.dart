import 'package:flutter/material.dart';

import '../../data/item/bag.dart';

class BattleBagScreen extends StatefulWidget {
  const BattleBagScreen(this.bag, {super.key});

  final Bag bag;
  @override
  State<StatefulWidget> createState() => _BattleBagScreenState();
}

class _BattleBagScreenState extends State<BattleBagScreen> {
  ItemCategory pocket = ItemCategory.values.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bag'),
      content: Column(children: [
        DropdownButton<ItemCategory>(
            value: pocket,
            items: ItemCategory.values
                .map((pocket) => DropdownMenuItem(
                    value: pocket, child: Text(pocket.name)))
                .toList(),
            onChanged: (value) {
              setState((){
                pocket = value!;
              });
            }),
        for (final slot in widget.bag.pockets[pocket] ?? [])
          TextButton(
            child: Text('${slot.item.name} x ${slot.quantity}'),
            onPressed: () => Navigator.of(context).pop(slot.item),
          ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ]),
    );
  }
}
