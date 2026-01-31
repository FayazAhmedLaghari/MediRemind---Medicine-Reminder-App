// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'MediRemind';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get email => 'Ingrese su correo electrónico';

  @override
  String get password => 'Ingrese su contraseña';

  @override
  String get forgotPassword => '¿Olvidó su contraseña?';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get dashboardTitle => 'Panel del paciente';

  @override
  String get myMedicines => 'Mis medicamentos';

  @override
  String get scanPrescription => 'Escanear receta';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get profile => 'Perfil';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get confirmLogout => 'Confirmar cierre de sesión';

  @override
  String get logoutConfirmation =>
      '¿Está seguro de que desea cerrar la sesión?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get addReminder => 'Agregar recordatorio';

  @override
  String get medicineName => 'Nombre del medicamento';

  @override
  String get dosage => 'Dosis';

  @override
  String get frequency => 'Frecuencia';

  @override
  String get time => 'Hora';

  @override
  String get notes => 'Notas';

  @override
  String get save => 'Guardar';

  @override
  String get edit => 'Editar';

  @override
  String get deleteMedicine => '¿Eliminar medicamento?';

  @override
  String deleteConfirmation(Object medicineName) {
    return '¿Está seguro de que desea eliminar $medicineName?';
  }

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get medicineInteraction => 'Posible interacción con otro medicamento';

  @override
  String get refillReminder =>
      'Recordatorio de reposición: Verifique el nivel de suministro';

  @override
  String get noMedicines => 'Aún no hay medicamentos';

  @override
  String get addFirstMedicine => 'Agregue su primer medicamento para comenzar';

  @override
  String get noReminders => 'No hay recordatorios para este día';

  @override
  String get markDone => 'Marcar como hecho';

  @override
  String get calendar => 'Calendario';

  @override
  String get today => 'Hoy';

  @override
  String get medicineAdded => 'Medicamento agregado exitosamente';

  @override
  String get reminderAdded => 'Recordatorio agregado exitosamente';

  @override
  String get markedCompleted => 'Marcado como completado';

  @override
  String get medicineDeleted => 'Medicamento eliminado';

  @override
  String get loggedOut => 'Sesión cerrada exitosamente';

  @override
  String get loginFailed => 'Error al iniciar sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get name => 'Nombre';

  @override
  String get age => 'Edad';

  @override
  String get gender => 'Género';

  @override
  String get medicalHistory => 'Historial médico';

  @override
  String get repeatPassword => 'Repita la contraseña';

  @override
  String get alreadyHaveAccount => '¿Ya tiene una cuenta?';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get selectMedicine => 'Seleccionar medicamento';

  @override
  String get reminderTime => 'Hora del recordatorio';

  @override
  String get selectTime => 'Seleccionar hora';

  @override
  String get medicineInteractionsTitle => 'Interacciones medicamentosas';

  @override
  String get refillRemindersTitle => 'Recordatorios de reposición';

  @override
  String interactionsFound(Object count) {
    return 'Interacciones encontradas: $count';
  }

  @override
  String refillsNeeded(Object count) {
    return 'Reposiciones necesarias: $count';
  }
}
