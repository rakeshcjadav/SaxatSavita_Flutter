import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/aashirvachan_model.dart';
import 'package:saxatsavita_flutter/pages/aashirvachanpage.dart';

class Aashirvachanpage extends StatelessWidget {
  const Aashirvachanpage({super.key});

  List<AashirvachanModel> getAashirvachan() {
    return [
      AashirvachanModel(
        title: 'પ.પૂ.સદ્. શ્રી જોગી સ્વામી',
        tag: 'jogiswami',
        image: 'assets/res/z_ashirvachan_jogiswami_image.webp',
        content: AashirvachanContent(
          image: null,
          text: 'aashirvachan_jogiswami_content',
        ),
      ),
      AashirvachanModel(
        title: 'પૂ. સ્વામીશ્રી',
        tag: 'swamishree',
        image: 'assets/res/z_ashirvachan_swami_shree_image.webp',
        content: AashirvachanContent(
          image: 'assets/res/z_ashirvachan_swami_shree.webp',
          text: null,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.aashirvachan,
        actionItems: [ActionOptions.info, ActionOptions.settings],
      ),
      body: ListView.builder(
        itemCount: getAashirvachan().length,
        itemBuilder: (context, index) {
          final aashirvachan = getAashirvachan()[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AashirvachanDetailPage(
                              aashirvachan: aashirvachan,
                            ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: '${aashirvachan.tag}-image',
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          aashirvachan.image,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  aashirvachan.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
