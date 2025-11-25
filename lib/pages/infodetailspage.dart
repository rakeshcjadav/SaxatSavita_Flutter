import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/helpers/html_to_textspan.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/inspirational_quote_model.dart';
import 'package:saxatsavita_flutter/pages/quotes_image_generator_page.dart';
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
          top: 0.0,
          bottom: 0.0,
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
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
              child: Scrollbar(
                interactive: true,
                child: SingleChildScrollView(
                  primary: true,
                  child: GestureDetector(
                    onTap: () {
                      //FocusScope.of(context).unfocus();
                      debugPrint("Unfocus TextField");
                    },
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 6.0,
                          right: 6.0,
                          top: 12.0,
                          bottom: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: HtmlToTextSpan.convertToWidgets(
                            strContent,
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: appSettingsNotifier.value.fontSize,
                            ),
                            context,
                            textAlign: TextAlign.justify,
                            lineHeight: appSettingsNotifier.value.lineHeight,

                            onCreateQuoteImage: (selectedText) async {
                              final InspirationalQuote quote =
                                  InspirationalQuote(
                                    quote: selectedText!,
                                    author: infoItem.title,
                                    kiranIndex: -1,
                                    partNumber: -1,
                                  );
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => QuotesImageGeneratorPage(
                                        quote: quote,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
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
