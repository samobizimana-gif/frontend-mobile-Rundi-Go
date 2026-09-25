import 'package:flutter/material.dart';
import 'api_client.dart';
import 'app_toast.dart';

/// Affiche un toast d'erreur propre selon le type d'exception.
void showApiError(BuildContext context, dynamic error) {
  String message;

  if (error is NetworkException) {
    message = "Pas de connexion. Vérifiez votre réseau.";
  } else if (error is ApiException) {
    if (error.statusCode == 401) {
      message = "Session expirée. Reconnectez-vous.";
    } else if (error.statusCode == 403) {
      message = "Vous n'avez pas accès à cette ressource.";
    } else if (error.statusCode == 404) {
      message = "Ressource introuvable.";
    } else if (error.statusCode == 422) {
      message = "Données invalides.";
    } else if (error.statusCode == 502) {
      message = "Erreur de passerelle. Réessayez.";
    } else {
      message = error.message;
    }
  } else if (error is String) {
    message = error;
  } else {
    message = "Une erreur est survenue.";
  }

  AppToast.error(context, message);
}

/// Affiche un message de succès.
void showSuccess(BuildContext context, String message) {
  AppToast.success(context, message);
}

/// Affiche un message d'information.
void showInfo(BuildContext context, String message) {
  AppToast.info(context, message);
}

/// Affiche un avertissement.
void showWarning(BuildContext context, String message) {
  AppToast.warning(context, message);
}

/// Widget standard pour un état d'erreur (à utiliser dans les écrans).
Widget buildErrorState({
  required String message,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          const Text("Oups...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Réessayer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Widget standard pour un état "vide".
Widget buildEmptyState({
  required IconData icon,
  required String title,
  String? subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: const Color(0xFF1E88E5)),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ],
      ),
    ),
  );
}