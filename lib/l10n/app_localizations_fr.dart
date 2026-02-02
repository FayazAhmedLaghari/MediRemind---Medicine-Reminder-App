// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'MediRemind';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get login => 'Se connecter';

  @override
  String get email => 'Entrez votre email';

  @override
  String get password => 'Entrez votre mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get dashboardTitle => 'Tableau de bord du patient';

  @override
  String get myMedicines => 'Mes médicaments';

  @override
  String get scanPrescription => 'Scanner l\'ordonnance';

  @override
  String get reminders => 'Rappels';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Déconnexion';

  @override
  String get confirmLogout => 'Confirmer la déconnexion';

  @override
  String get logoutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get addReminder => 'Ajouter un rappel';

  @override
  String get medicineName => 'Nom du médicament';

  @override
  String get dosage => 'Dosage';

  @override
  String get frequency => 'Fréquence';

  @override
  String get time => 'Heure';

  @override
  String get notes => 'Notes';

  @override
  String get save => 'Enregistrer';

  @override
  String get edit => 'Modifier';

  @override
  String get deleteMedicine => 'Supprimer le médicament ?';

  @override
  String deleteConfirmation(Object medicineName) {
    return 'Êtes-vous sûr de vouloir supprimer $medicineName ?';
  }

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get medicineInteraction =>
      'Interaction potentielle avec un autre médicament';

  @override
  String get refillReminder =>
      'Rappel de réapprovisionnement : Vérifiez le niveau de stock';

  @override
  String get noMedicines => 'Aucun médicament pour le moment';

  @override
  String get addFirstMedicine =>
      'Ajoutez votre premier médicament pour commencer';

  @override
  String get noReminders => 'Aucun rappel pour cette journée';

  @override
  String get markDone => 'Marquer comme terminé';

  @override
  String get calendar => 'Calendrier';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get todaysMedicines => 'Médicaments du jour';

  @override
  String get personalNotes => 'Notes personnelles';

  @override
  String get doctorInstructions => 'Instructions du médecin';

  @override
  String get noNotes => 'Pas encore de notes';

  @override
  String get saveNotes => 'Enregistrer les notes';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get sindhi => 'سنڌي';

  @override
  String get medicineAdded => 'Médicament ajouté avec succès';

  @override
  String get reminderAdded => 'Rappel ajouté avec succès';

  @override
  String get markedCompleted => 'Marqué comme terminé';

  @override
  String get medicineDeleted => 'Médicament supprimé';

  @override
  String get loggedOut => 'Déconnexion réussie';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get name => 'Nom';

  @override
  String get age => 'Âge';

  @override
  String get gender => 'Genre';

  @override
  String get medicalHistory => 'Historique médical';

  @override
  String get repeatPassword => 'Répéter le mot de passe';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get selectMedicine => 'Sélectionner un médicament';

  @override
  String get reminderTime => 'Heure du rappel';

  @override
  String get selectTime => 'Sélectionner l\'heure';

  @override
  String get medicineInteractionsTitle => 'Interactions médicamenteuses';

  @override
  String get refillRemindersTitle => 'Rappels de réapprovisionnement';

  @override
  String interactionsFound(Object count) {
    return 'Interactions trouvées : $count';
  }

  @override
  String refillsNeeded(Object count) {
    return 'Réapprovisionnements nécessaires : $count';
  }
}
