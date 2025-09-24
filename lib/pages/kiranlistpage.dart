import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranlist_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import '../models/bookpart_model.dart';
import '../services/kiranuser_service.dart';

class Kiranlistpage extends StatefulWidget {
  final Bookpartmodel bookPart;
  const Kiranlistpage({super.key, required this.bookPart});

  @override
  State<Kiranlistpage> createState() => _KiranlistpageState();
}

class _KiranlistpageState extends State<Kiranlistpage> {
  late Future<KiranList> _futureKiranList;

  @override
  void initState() {
    super.initState();
    KiranUserService().buildKiranUserInfoList();
    _futureKiranList =
        KiranListService().getKiranList(widget.bookPart.id) != null
            ? Future.value(KiranListService().getKiranList(widget.bookPart.id))
            : KiranListService()
                .loadPart("saxatsavita", widget.bookPart.id)
                .then((_) {
                  return KiranListService().getKiranList(widget.bookPart.id)!;
                });
  }

  int? _expandedIndex;

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToKiranReadPage(KiranInfo kiran, KiranUserInfo kiranUserInfo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => KiranReadPage(
              partNumber: widget.bookPart.id,
              kiranInfo: kiran,
              kiranUserInfo: kiranUserInfo,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: widget.bookPart.displayname,
        actionItems: [ActionOptions.info, ActionOptions.settings],
      ),
      body: FutureBuilder<KiranList>(
        future: _futureKiranList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.list.isEmpty) {
            return const Center(child: Text('No kirans found.'));
          }
          final kirans = snapshot.data!.list;
          return ListView.builder(
            itemCount: kirans.length,
            itemBuilder: (context, index) {
              final kiran = kirans[index];
              final kiranUserInfo =
                  KiranUserService().getKiranUserInfo(kiran.index)!;
              return Card(
                child: ExpansionTile(
                  showTrailingIcon: true,
                  key: Key(kiran.index.toString()),
                  initiallyExpanded: _expandedIndex == index,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedIndex = expanded ? index : null;
                    });
                  },
                  title: _buildKiranListItemWidget(
                    kiran,
                    kiranUserInfo,
                    _expandedIndex == index,
                  ),
                  children: _buildKiranListItemExpandedWidget(
                    kiran,
                    kiranUserInfo,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildKiranListItemExpandedWidget(
    KiranInfo kiran,
    KiranUserInfo kiranUserInfo,
  ) {
    return [
      ListTile(subtitle: Text('Words: ${kiran.wordCount}')),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListTile(
          title: Text(kiran.title),
          trailing: ElevatedButton(
            onPressed: () {
              _navigateToKiranReadPage(kiran, kiranUserInfo);
            },
            child: const Text('Read'),
          ),
        ),
      ),
    ];
  }

  Widget _buildKiranListItemWidget(
    KiranInfo kiran,
    KiranUserInfo kiranUserInfo,
    bool isExpanded,
  ) {
    return ListTile(
      title: Row(
        children: [
          Text(kiran.number, style: Theme.of(context).textTheme.titleSmall),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              kiran.title,
              overflow: TextOverflow.clip,
              softWrap: true,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, size: 16),
              SizedBox(width: 4),
              Text(
                '#${kiran.wordCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Spacer(),
              if (kiranUserInfo.isFavourite == 1)
                Icon(Icons.favorite, size: 16),
              if (kiranUserInfo.isFavourite == 0)
                Icon(Icons.favorite_border, size: 16),
              Spacer(),
              Text(
                'vanchan: #${kiranUserInfo.readCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 100 / kiran.wordCount,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
