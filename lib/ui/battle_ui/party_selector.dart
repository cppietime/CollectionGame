import 'package:flutter/material.dart';

import '../../battle/battle.dart';

class PartySelector extends StatelessWidget {
  const PartySelector(this.player, this.canCancel, this.toSendOut, {super.key});
  final BattlePlayer player;
  final bool canCancel;
  final bool toSendOut;

  @override
  Widget build(BuildContext context) {
    final canSend = player.party.map((member) =>
        member.hp > 0 &&
            (!player.activeBattlers.values
            .any((battler) => battler.individual == member))).toList();
    return AlertDialog(
      title: const Text('Choose a party member'),
      content: Container(
        width: double.maxFinite,
        child: ListView(scrollDirection: Axis.vertical, children: [
          for (int i = 0; i < player.party.length; i++)
            ListTile(
              title: Text('${player.party[i]}'),
              onTap: () {
                if (canSend[i] || !toSendOut) {
                  Navigator.of(context).pop(i);
                }
              },
            ),
          if (canCancel)
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(null),
            ),
        ]),
      ),
    );
  }
}
