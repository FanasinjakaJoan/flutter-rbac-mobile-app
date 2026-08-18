abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _matricule = RegExp(r'^MAT-\d{5}$', caseSensitive: false);
  static final _usernameOrId = RegExp(r'^[a-zA-Z0-9._-]{3,}$');

  static String? identifier(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Saisissez votre email, matricule ou identifiant.';
    }
    if (!_email.hasMatch(input) &&
        !_matricule.hasMatch(input) &&
        !_usernameOrId.hasMatch(input)) {
      return 'Le format de l’identifiant est invalide.';
    }
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Saisissez votre mot de passe.';
    }
    if (input.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (!RegExp('[A-Za-z]').hasMatch(input) ||
        !RegExp('[0-9]').hasMatch(input)) {
      return 'Utilisez au moins une lettre et un chiffre.';
    }
    return null;
  }

  static String? recoveryIdentifier(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Saisissez votre email ou votre matricule.';
    }
    if (!_email.hasMatch(input) && !_matricule.hasMatch(input)) {
      return 'Saisissez un email ou un matricule valide.';
    }
    return null;
  }

  static String? resetCode(String? value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')) {
      return 'Le code doit contenir 6 chiffres.';
    }
    return null;
  }
}
