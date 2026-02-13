import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);
    final history = context.watch<HistoryController>();

    return FarmBackgroundScaffold(
      title: strings('history'),
      backgroundColor: Colors.transparent,
      child: RefreshIndicator(
        onRefresh: () => context.read<HistoryController>().refresh(),
        child: history.items.isEmpty 
          ? _EmptyHistory(t: t)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: history.items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ESCANEOS GUARDADOS', 
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1.2, 
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.read<HistoryController>().refresh(),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }
                final item = history.items[i - 1];
                return _HistoryCard(item: item);
              },
            ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final ScanResult item;

  @override
  Widget build(BuildContext context) {
    final animal = AnimalsCatalog.byId(item.animalId);
    final dateLabel = DateFormat('dd MMM, yyyy • HH:mm').format(item.createdAt);
    final thumbBytes = item.photosBase64.isNotEmpty ? base64Decode(item.photosBase64.first) : null;

    final Color healthColor = item.healthStatus == 'buena' 
        ? Colors.greenAccent 
        : (item.healthStatus == 'regular' ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      decoration: BoxDecoration(
