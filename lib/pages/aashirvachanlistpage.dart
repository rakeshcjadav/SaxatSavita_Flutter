import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/aashirvachan_model.dart';

class Aashirvachanpage extends StatelessWidget {
  const Aashirvachanpage({super.key});

  List<AashirvachanModel> getAashirvachan() {
    return [
      AashirvachanModel(
        title: 'પ.પૂ.સદ્. શ્રી જોગી સ્વામી',
        tag: 'jogiswami',
        image: 'assets/res/z_ashirvachan_jogiswami_image.webp',
        content: AashirvachanContent(
          image: 'assets/res/z_ashirvachan_jogiswami_image.webp',
          text: 'Jogi Swami',
        ),
      ),
      AashirvachanModel(
        title: 'પૂ. સ્વામીશ્રી',
        tag: 'swamishree',
        image: 'assets/res/z_ashirvachan_swami_shree_image.webp',
        content: AashirvachanContent(
          image: 'assets/res/z_ashirvachan_swami_shree_image.webp',
          text: 'Swamishree',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.orange.shade100;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.aashirvachan,
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
                Hero(
                  tag: '${aashirvachan.tag}-image',
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        aashirvachan.image,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  aashirvachan.title,
                  style: TextStyle(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
