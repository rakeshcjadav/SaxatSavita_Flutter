import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/helpers/kiran_tithi.dart';

void main() {
  test('reads the lunar month and tithi from the origin line', () {
    expect(
      kiranTithiFromMetaDate(
        'સંવત્‌ ૨૦૩૧ વૈશાખ સુદિ-૧૦, તા. ૨૦-૫-૭૫ મંગળવાર, બપોરની કથા',
      ),
      'સંવત્ ૨૦૩૧ વૈશાખ સુદિ-૧૦',
    );
    expect(
      kiranTithiFromMetaDate('સંવત્ ૨૦૩૧ અષાઢ વદિ-૧૨, તા. ૪-૮-૭૫ સોમવાર'),
      'સંવત્ ૨૦૩૧ અષાઢ વદિ-૧૨',
    );
    expect(kiranTithiFromMetaDate('વૈશાખ સુદિ-૧૦'), 'વૈશાખ સુદિ-૧૦');
  });

  test('returns null when the line has no tithi', () {
    expect(kiranTithiFromMetaDate(''), isNull);
    expect(kiranTithiFromMetaDate('તા. ૨૦-૫-૭૫'), isNull);
  });
}
