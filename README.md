# Portail Flutter RBAC

Application Flutter complète de démonstration pour une authentification **multi-identifiant** et un contrôle d’accès par rôles (**RBAC**). L’application fonctionne sans serveur : une source de données locale simule la latence d’une API, les réponses utilisateur et des jetons JWT valides pendant 24 heures.

## Fonctionnalités

- connexion avec un seul champ acceptant un email, un matricule (`MAT-12345`) ou un nom d’utilisateur/ID ;
- validation du mot de passe et bouton afficher/masquer ;
- restauration et suppression de session avec `flutter_secure_storage` ;
- état global d’authentification géré avec `flutter_bloc` ;
- navigation déclarative `go_router` et redirections réactives ;
- permissions RBAC contrôlées à chaque route protégée ;
- tableaux de bord distincts pour administrateur, étudiant et technicien ;
- écrans de récupération de mot de passe et de saisie OTP ;
- client `dio` prêt pour une API réelle, avec ajout automatique du jeton `Bearer` et suppression du jeton sur une réponse HTTP 401 ;
- tests unitaires du dépôt/BLoC et tests widget des gardes de navigation.

## Comptes de démonstration

Tous les comptes utilisent le mot de passe **`Password123!`**.

| Rôle | Email | Matricule ou ID | Nom d’utilisateur |
|---|---|---|---|
| Administrateur | `admin@example.com` | `ADM-001` | `admin` |
| Étudiant | `student@example.com` | `MAT-12345` | `student` |
| Technicien | `technician@example.com` | `TEC-001` | `technician` |

Le code OTP de démonstration est **`123456`**.

## Matrice d’accès

| Route | Permission | Rôle autorisé |
|---|---|---|
| `/admin/dashboard` | `viewAdminDashboard` | `admin` |
| `/student/dashboard` | `viewStudentDashboard` | `student` |
| `/technician/dashboard` | `viewTechnicianDashboard` | `technician` |

Les routes `/login`, `/forgot-password` et `/reset-code` sont publiques. Une personne non authentifiée qui ouvre une route protégée est redirigée vers `/login`. Une session authentifiée sans la permission demandée est redirigée vers `/unauthorized`.

## Prérequis

- Flutter 3.44 ou version ultérieure avec Dart 3.12+ ;
- Android Studio/SDK avec une cible Android 6.0 (API 23) ou ultérieure ;
- Xcode et CocoaPods pour iOS.

Vérifier l’environnement :

```bash
flutter doctor
```

## Installation et exécution

```bash
git clone <url-du-depot>
cd flutter-rbac-mobile-app
flutter pub get
flutter run
```

Pour choisir une cible :

```bash
flutter devices
flutter run -d <identifiant-de-la-cible>
```

Les plateformes Android, iOS et Web sont initialisées. Pour iOS, `flutter run` installe les pods lors de la première construction ; au besoin, exécuter `cd ios && pod install && cd ..`.

## Qualité et tests

```bash
flutter analyze
flutter test
```

Les scénarios couverts incluent :

- authentification par email, matricule et nom d’utilisateur ;
- persistance/restauration du JWT et rejet d’un jeton invalide ;
- transitions du `AuthBloc` ;
- redirection vers la connexion lorsque la session est absente ;
- redirection vers l’écran non autorisé en cas de rôle incorrect ;
- accès d’un administrateur à sa route autorisée.

## Architecture

```text
lib/
├── app.dart
├── main.dart
├── core/
│   ├── app_dependencies.dart
│   ├── constants/       # constantes et chemins de routes
│   ├── error/           # erreurs métier partagées
│   ├── network/         # client Dio et intercepteur Bearer
│   ├── router/          # go_router, redirections et gardes RBAC
│   ├── security/        # rôles, permissions et stockage sécurisé
│   ├── theme/           # thème Material 3
│   └── widgets/         # composants transverses
└── features/
    ├── auth/
    │   ├── data/        # modèles, source API simulée, dépôt concret
    │   ├── domain/      # entités, contrat du dépôt et cas d’usage
    │   └── presentation/# BLoC/Cubit, validateurs et écrans
    └── dashboard/
        └── presentation/# dashboards admin, étudiant et technicien
```

### Flux d’authentification

1. `AuthBloc` reçoit `AppStarted` et demande au dépôt de restaurer la session.
2. `AuthRepositoryImpl` lit le JWT dans `TokenStorage`.
3. La source simulée décode le JWT, contrôle son expiration et reconstruit l’utilisateur.
4. `go_router` écoute le flux du BLoC et recalcule sa redirection.
5. `RbacPolicy` associe le chemin demandé à une permission puis vérifie le rôle courant.

### Passage à une API réelle

`DioClient` et `AuthInterceptor` sont déjà configurés dans `AppDependencies`. Pour connecter un backend, remplacer `MockAuthRemoteDataSource` par une implémentation de `AuthRemoteDataSource` basée sur l’instance `Dio`, sans modifier le domaine, le BLoC ou les écrans.

## Sécurité de la démonstration

Le jeton a le format d’un JWT mais sa signature est factice : il ne doit pas être utilisé en production. Dans une application réelle, la signature et l’autorisation doivent toujours être validées côté serveur, les mots de passe ne doivent jamais être embarqués dans le client et le rafraîchissement des jetons doit être géré par l’API.
