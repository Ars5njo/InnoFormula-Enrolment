import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/asset_meeting_repository.dart';
import 'presentation/app.dart';

void main() {
  runApp(InnoFormulaApp(repository: AssetMeetingRepository(rootBundle)));
}
