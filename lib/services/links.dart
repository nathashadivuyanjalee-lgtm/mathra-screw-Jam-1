import 'package:url_launcher/url_launcher.dart';
import '../models/brand.dart';

Future<bool> openUrl(String url) async {
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> callCreator() => openUrl('tel:${Brand.phone}');
Future<bool> whatsappCreator() => openUrl(Brand.whatsappUrl);
Future<bool> openTikTok() => openUrl(Brand.tiktokUrl);
Future<bool> openGithub() => openUrl(Brand.githubUrl);
