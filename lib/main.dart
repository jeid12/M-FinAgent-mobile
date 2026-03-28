import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Avoid runtime font file caching that depends on path_provider plugin channels.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const FinAgentApp());
}
