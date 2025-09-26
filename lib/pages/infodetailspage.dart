import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/customHtmlWidget.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import '../models/infocontent_model.dart';
import '../components/appbar.dart';

class Infodetailspage extends StatelessWidget {
  const Infodetailspage({super.key, required this.infoItem});

  final InfoContentModel infoItem;

  @override
  Widget build(BuildContext context) {
    String strContent = infoItem.content.replaceAll('&nbsp; &nbsp;', '󠁪⠀ ');
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.information,
        actionItems: [ActionOptions.settings],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: .0,
          bottom: 16,
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withOpacity(1.0),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  infoItem.title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: GestureDetector(
                  onTap: () {
                    //FocusScope.of(context).unfocus();
                    debugPrint("Unfocus TextField");
                  },
                  child: SafeArea(
                    child: CustomHtmlWidget(htmlContent: strContent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
