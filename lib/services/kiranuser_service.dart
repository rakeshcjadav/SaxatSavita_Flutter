import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';

class KiranUserService {
  static final KiranUserService _instance = KiranUserService._internal();
  factory KiranUserService() => _instance;
  KiranUserService._internal();

  List<KiranUserInfo> _kiranUserInfoList = [];

  List<KiranUserInfo> get kiranUserInfoList {
    if (_kiranUserInfoList.isEmpty) {
      buildKiranUserInfoList();
    }
    return _kiranUserInfoList;
  }

  set kiranUserInfoList(List<KiranUserInfo> list) {
    _kiranUserInfoList = list;
  }

  void insertKiranUserInfoList(List<KiranUserInfo> list) {
    if (_kiranUserInfoList.isEmpty) {
      _kiranUserInfoList = [];
      buildKiranUserInfoList();
    }
    if (_kiranUserInfoList.isNotEmpty) {
      // list is subset of existing list, so update existing entries
      for (var newInfo in list) {
        final index = _kiranUserInfoList.indexWhere(
          (k) => k.kiranIndex == newInfo.kiranIndex,
        );
        if (index >= 0) {
          _kiranUserInfoList[index] = newInfo;
        } else {
          _kiranUserInfoList.add(newInfo);
        }
      }
    } else {
      _kiranUserInfoList = list;
    }
  }

  KiranUserInfo getKiranUserInfo(int kiranIndex) {
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
