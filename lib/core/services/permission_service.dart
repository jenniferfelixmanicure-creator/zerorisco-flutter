import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAll(BuildContext context) async {
    await _requestLocation(context);
    await _requestCamera(context);
    await _requestMicrophone(context);
  }

  static Future<bool> requestLocation(BuildContext context) {
    return _requestLocation(context);
  }

  static Future<bool> requestCamera(BuildContext context) {
    return _requestCamera(context);
  }

  static Future<bool> requestMicrophone(BuildContext context) {
    return _requestMicrophone(context);
  }

  static Future<bool> _requestLocation(BuildContext context) async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, 'Localização', 'Para usar o app de transporte, precisamos acessar sua localização.');
      return false;
    }

    status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      await Permission.locationAlways.request();
      return true;
    }
    return false;
  }

  static Future<bool> _requestCamera(BuildContext context) async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, 'Câmera', 'Precisamos da câmera para foto de perfil e documentos.');
      return false;
    }

    status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> _requestMicrophone(BuildContext context) async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, 'Microfone', 'O microfone é usado para suporte durante emergências.');
      return false;
    }

    status = await Permission.microphone.request();
    return status.isGranted;
  }

  static void _showSettingsDialog(BuildContext context, String permission, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Permissão de $permission',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '$reason\n\nAbra as configurações do app para habilitar.',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Agora não', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C896)),
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
    );
  }

  static Future<Map<String, bool>> checkAll() async {
    final results = await [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.microphone,
    ].request();

    return {
      'location': results[Permission.locationWhenInUse]?.isGranted ?? false,
      'camera': results[Permission.camera]?.isGranted ?? false,
      'microphone': results[Permission.microphone]?.isGranted ?? false,
    };
  }
}
