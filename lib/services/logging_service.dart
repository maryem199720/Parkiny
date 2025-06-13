import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Service de logging et de gestion d'erreur pour l'application Smart Parking
class LoggingService {
  static const String _tag = 'SmartParking';

  /// Log d'information
  static void info(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    if (kDebugMode) {
      developer.log(message, name: logTag, level: 800);
    }
    print('[INFO][$logTag] $message');
  }

  /// Log d'erreur
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final logTag = tag ?? _tag;
    if (kDebugMode) {
      developer.log(
        message,
        name: logTag,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
    print('[ERROR][$logTag] $message');
    if (error != null) {
      print('[ERROR][$logTag] Exception: $error');
    }
    if (stackTrace != null) {
      print('[ERROR][$logTag] StackTrace: $stackTrace');
    }
  }

  /// Log de warning
  static void warning(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    if (kDebugMode) {
      developer.log(message, name: logTag, level: 900);
    }
    print('[WARNING][$logTag] $message');
  }

  /// Log de debug
  static void debug(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    if (kDebugMode) {
      developer.log(message, name: logTag, level: 700);
      print('[DEBUG][$logTag] $message');
    }
  }

  /// Log des requêtes HTTP
  static void httpRequest(String method, String url, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    if (kDebugMode) {
      info('HTTP $method: $url', tag: 'HTTP');
      if (headers != null) {
        debug('Headers: $headers', tag: 'HTTP');
      }
      if (body != null) {
        debug('Body: $body', tag: 'HTTP');
      }
    }
  }

  /// Log des réponses HTTP
  static void httpResponse(int statusCode, String url, {String? body}) {
    if (kDebugMode) {
      info('HTTP Response [$statusCode]: $url', tag: 'HTTP');
      if (body != null && body.isNotEmpty) {
        debug('Response Body: $body', tag: 'HTTP');
      }
    }
  }

  /// Log des erreurs de réservation spécifiquement
  static void reservationError(String operation, dynamic error, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    LoggingService.error(
      'Erreur de réservation lors de: $operation',
      tag: 'RESERVATION',
      error: error,
      stackTrace: stackTrace,
    );
    if (context != null) {
      debug('Contexte: $context', tag: 'RESERVATION');
    }
  }

  /// Log des étapes de réservation
  static void reservationStep(String step, {Map<String, dynamic>? data}) {
    info('Étape de réservation: $step', tag: 'RESERVATION');
    if (data != null) {
      debug('Données: $data', tag: 'RESERVATION');
    }
  }
}

/// Service de gestion d'erreur centralisé
class ErrorHandlingService {
  /// Gère les erreurs HTTP et retourne un message utilisateur approprié
  static String handleHttpError(int statusCode, String? responseBody) {
    switch (statusCode) {
      case 400:
        return 'Données invalides. Veuillez vérifier vos informations.';
      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
      case 404:
        return 'Ressource non trouvée. Veuillez réessayer.';
      case 409:
        return 'Conflit détecté. Cette action ne peut pas être effectuée.';
      case 422:
        return 'Données non valides. Veuillez corriger les erreurs.';
      case 500:
        return 'Erreur serveur. Veuillez réessayer plus tard.';
      case 502:
        return 'Service temporairement indisponible.';
      case 503:
        return 'Service en maintenance. Veuillez réessayer plus tard.';
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return 'Erreur client (Code: $statusCode). Veuillez vérifier vos données.';
        } else if (statusCode >= 500) {
          return 'Erreur serveur (Code: $statusCode). Veuillez réessayer plus tard.';
        }
        return 'Erreur inattendue (Code: $statusCode).';
    }
  }

  /// Gère les erreurs de réseau
  static String handleNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Délai d\'attente dépassé. Vérifiez votre connexion internet.';
    } else if (errorString.contains('socket') || errorString.contains('connection')) {
      return 'Problème de connexion. Vérifiez votre réseau.';
    } else if (errorString.contains('certificate') || errorString.contains('ssl')) {
      return 'Problème de sécurité de connexion.';
    } else if (errorString.contains('host')) {
      return 'Impossible de joindre le serveur.';
    }

    return 'Erreur de réseau. Vérifiez votre connexion internet.';
  }

  /// Gère les erreurs de réservation spécifiques
  static String handleReservationError(dynamic error, {String? context}) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('id') && errorString.contains('retournée')) {
      return 'Erreur lors de la création de la réservation. Le serveur n\'a pas retourné d\'identifiant. Veuillez réessayer.';
    } else if (errorString.contains('place') && errorString.contains('disponible')) {
      return 'Cette place n\'est plus disponible. Veuillez en choisir une autre.';
    } else if (errorString.contains('véhicule')) {
      return 'Problème avec le véhicule sélectionné. Veuillez en choisir un autre.';
    } else if (errorString.contains('abonnement')) {
      return 'Problème avec votre abonnement. Veuillez vérifier son statut.';
    } else if (errorString.contains('paiement')) {
      return 'Erreur de paiement. Veuillez vérifier vos informations de paiement.';
    }

    return 'Erreur lors de la réservation. Veuillez réessayer.';
  }

  /// Valide les données de réservation avant envoi
  static List<String> validateReservationData({
    required int? userId,
    required int? parkingSpotId,
    required int? vehicleId,
    required String? date,
    required String? startTime,
    required String? endTime,
  }) {
    final errors = <String>[];

    if (userId == null) {
      errors.add('ID utilisateur manquant');
    }

    if (parkingSpotId == null) {
      errors.add('Place de parking non sélectionnée');
    }

    if (vehicleId == null) {
      errors.add('Véhicule non sélectionné');
    }

    if (date == null || date.isEmpty) {
      errors.add('Date non spécifiée');
    }

    if (startTime == null || startTime.isEmpty) {
      errors.add('Heure de début non spécifiée');
    }

    if (endTime == null || endTime.isEmpty) {
      errors.add('Heure de fin non spécifiée');
    }

    // Validation du format de date
    if (date != null && date.isNotEmpty) {
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!dateRegex.hasMatch(date)) {
        errors.add('Format de date invalide (attendu: YYYY-MM-DD)');
      }
    }

    // Validation du format d'heure
    if (startTime != null && startTime.isNotEmpty) {
      final timeRegex = RegExp(r'^\d{2}:\d{2}$');
      if (!timeRegex.hasMatch(startTime)) {
        errors.add('Format d\'heure de début invalide (attendu: HH:MM)');
      }
    }

    if (endTime != null && endTime.isNotEmpty) {
      final timeRegex = RegExp(r'^\d{2}:\d{2}$');
      if (!timeRegex.hasMatch(endTime)) {
        errors.add('Format d\'heure de fin invalide (attendu: HH:MM)');
      }
    }

    return errors;
  }
}

/// Service de retry pour les opérations réseau
class RetryService {
  /// Exécute une opération avec retry automatique
  static Future<T> executeWithRetry<T>(
      Future<T> Function() operation, {
        int maxRetries = 3,
        Duration delay = const Duration(seconds: 2),
        bool Function(dynamic error)? shouldRetry,
      }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        LoggingService.debug('Tentative ${attempts + 1}/$maxRetries');
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          LoggingService.error(
              'Échec après $maxRetries tentatives', error: e);
          rethrow;
        }

        if (shouldRetry != null && !shouldRetry(e)) {
          LoggingService.warning('Retry annulé par la condition shouldRetry');
          rethrow;
        }
        LoggingService.warning(
            'Tentative ${attempts} échouée, retry dans ${delay.inSeconds}s');        await Future.delayed(delay);
      }   }

    throw Exception('Nombre maximum de tentatives atteint');
  }

  /// Détermine si une erreur HTTP justifie un retry
  static bool shouldRetryHttpError(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();

      // Retry pour les erreurs de réseau
      if (errorString.contains('timeout') ||
          errorString.contains('connection') ||
          errorString.contains('socket')) {
        return true;
      }

      // Retry pour les erreurs serveur 5xx
      if (errorString.contains('500') ||
          errorString.contains('502') ||
          errorString.contains('503') ||
          errorString.contains('504')) {
        return true;
      }
    }

    return false;
  }
}

