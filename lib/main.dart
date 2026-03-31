import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Sora is loaded via Google Fonts at runtime.
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const FinAgentApp());
}
