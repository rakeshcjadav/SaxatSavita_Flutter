import '../models/kiranuserinfo_model.dart';

class KiranUserService {
  static final KiranUserService _instance = KiranUserService._internal();
  factory KiranUserService() => _instance;
  KiranUserService._internal();

  List<KiranUserInfo> _kiranUserInfoList = [];

  KiranUserInfo? getKiranUserInfo(int kiranIndex) {
    if (_kiranUserInfoList.isEmpty) {
      _kiranUserInfoList = [];
      buildKiranUserInfoList();
    }
    return _kiranUserInfoList[kiranIndex - 1];
  }

  void buildKiranUserInfoList() {
    if (_kiranUserInfoList.isNotEmpty) {
      return;
    }
    final List<Range> listRanges = [
      Range(1, 170),
      Range(171, 362),
      Range(363, 501),
      Range(502, 600),
      Range(601, 697),
    ];

    int iPart = 1;
    for (final part in listRanges) {
      for (int i = part.lower; i <= part.upper; i++) {
        _kiranUserInfoList.add(
          KiranUserInfo(
            kiranIndex: i,
            listIndex: i - part.lower,
            partNumber: iPart,
          ),
        );
      }
      iPart++;
    }
  }
}
