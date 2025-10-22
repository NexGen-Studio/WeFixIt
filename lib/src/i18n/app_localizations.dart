import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Map<String, dynamic> _localized = {};

  Future<bool> load() async {
    final data = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    _localized = json.decode(data) as Map<String, dynamic>;
    return true;
  }

  String tr(String key) {
    final value = _localized[key];
    if (value is String) return value;
    return key;
  }

  // Maintenance i18n getters
  String get maintenance_dashboard_title => tr('maintenance.dashboard_title');
  String get maintenance_vehicle_overview => tr('maintenance.vehicle_overview');
  String get maintenance_quick_access => tr('maintenance.quick_access');
  String get maintenance_new_reminder => tr('maintenance.new_reminder');
  String get maintenance_costs => tr('maintenance.costs');
  String get maintenance_overdue_reminders => tr('maintenance.overdue_reminders');
  String get maintenance_overdue_badge => tr('maintenance.overdue_badge');
  String get maintenance_upcoming_reminders => tr('maintenance.upcoming_reminders');
  String get maintenance_no_upcoming => tr('maintenance.no_upcoming');
  String get maintenance_recently_completed => tr('maintenance.recently_completed');
  String get maintenance_due_in_days => tr('maintenance.due_in_days');
  String get maintenance_due_today => tr('maintenance.due_today');
  String get maintenance_overdue_days => tr('maintenance.overdue_days');
  
  String get maintenance_create_title => tr('maintenance.create_title');
  String get maintenance_edit_title => tr('maintenance.edit_title');
  String get maintenance_title_label => tr('maintenance.title_label');
  String get maintenance_title_hint => tr('maintenance.title_hint');
  String get maintenance_title_required => tr('maintenance.title_required');
  String get maintenance_reminder_type => tr('maintenance.reminder_type');
  String get maintenance_type_date => tr('maintenance.type_date');
  String get maintenance_type_mileage => tr('maintenance.type_mileage');
  String get maintenance_due_date_label => tr('maintenance.due_date_label');
  String get maintenance_mileage_label => tr('maintenance.mileage_label');
  String get maintenance_mileage_hint => tr('maintenance.mileage_hint');
  String get maintenance_mileage_required => tr('maintenance.mileage_required');
  String get maintenance_mileage_suffix => tr('maintenance.mileage_suffix');
  String get maintenance_recurring => tr('maintenance.recurring');
  String get maintenance_recurring_subtitle => tr('maintenance.recurring_subtitle');
  String get maintenance_interval => tr('maintenance.interval');
  String get maintenance_interval_3_months => tr('maintenance.interval_3_months');
  String get maintenance_interval_6_months => tr('maintenance.interval_6_months');
  String get maintenance_interval_12_months => tr('maintenance.interval_12_months');
  String get maintenance_description_label => tr('maintenance.description_label');
  String get maintenance_description_hint => tr('maintenance.description_hint');
  String get maintenance_cancel => tr('maintenance.cancel');
  String get maintenance_save => tr('maintenance.save');
  
  String get maintenance_delete_title => tr('maintenance.delete_title');
  String get maintenance_delete_message => tr('maintenance.delete_message');
  String get maintenance_delete_confirm => tr('maintenance.delete_confirm');
  String get maintenance_deleted_success => tr('maintenance.deleted_success');
  
  String get maintenance_mark_complete => tr('maintenance.mark_complete');
  String get maintenance_mark_incomplete => tr('maintenance.mark_incomplete');
  String get maintenance_edit => tr('maintenance.edit');
  String get maintenance_delete => tr('maintenance.delete');
  String get maintenance_completed_success => tr('maintenance.completed_success');
  String get maintenance_uncompleted_success => tr('maintenance.uncompleted_success');
  
  String get maintenance_error => tr('maintenance.error');

  // Chatbot i18n getters
  String get chatbot_subtitle => tr('chatbot.subtitle');
  String get chatbot_how_can_i_help => tr('chatbot.how_can_i_help');
  String get chatbot_ask_questions => tr('chatbot.ask_questions');
  String get chatbot_popular_questions => tr('chatbot.popular_questions');
  String get chatbot_question_engine_light => tr('chatbot.question_engine_light');
  String get chatbot_question_error_code => tr('chatbot.question_error_code');
  String get chatbot_question_maintenance => tr('chatbot.question_maintenance');
  String get chatbot_question_noise => tr('chatbot.question_noise');

  // Home i18n getters
  String get home_vehicle_overview => tr('home.vehicle_overview');
  String get home_my_vehicle => tr('home.my_vehicle');
  String get home_in_days => tr('home.in_days');
  String get home_read_dtcs => tr('home.read_dtcs');
  String get home_maintenance => tr('home.maintenance');
  String get home_costs => tr('home.costs');
  String get home_ask_toni => tr('home.ask_toni');
  String get home_read_dtcs_subtitle => tr('home.read_dtcs_subtitle');
  String get home_maintenance_subtitle => tr('home.maintenance_subtitle');
  String get home_costs_subtitle => tr('home.costs_subtitle');
  String get home_ask_toni_subtitle => tr('home.ask_toni_subtitle');
  String get home_tip_oil_title => tr('home.tip_oil_title');
  String get home_tip_oil_body => tr('home.tip_oil_body');
  String get home_login_required_title => tr('home.login_required_title');
  String get home_login_required_message => tr('home.login_required_message');
  String get home_login_cancel => tr('home.login_cancel');
  String get home_login_confirm => tr('home.login_confirm');
  String get home_no_maintenance_title => tr('home.no_maintenance_title');
  String get home_no_maintenance_subtitle => tr('home.no_maintenance_subtitle');
  String get home_overdue => tr('home.overdue');
  String get home_due_today => tr('home.due_today');
  String get home_due_at_km => tr('home.due_at_km');

  // Diagnose i18n getters
  String get diagnose_how_it_works => tr('diagnose.how_it_works');
  String get diagnose_connect_adapter => tr('diagnose.connect_adapter');
  String get diagnose_connect_adapter_desc => tr('diagnose.connect_adapter_desc');
  String get diagnose_activate_bluetooth => tr('diagnose.activate_bluetooth');
  String get diagnose_activate_bluetooth_desc => tr('diagnose.activate_bluetooth_desc');
  String get diagnose_start_diagnosis => tr('diagnose.start_diagnosis');
  String get diagnose_start_diagnosis_desc => tr('diagnose.start_diagnosis_desc');
  String get diagnose_always_free => tr('diagnose.always_free');
  String get diagnose_may_use_credits => tr('diagnose.may_use_credits');

  // Profile i18n getters
  String get profile_profile_picture => tr('profile.profile_picture');
  String get profile_click_to_change => tr('profile.click_to_change');
  String get profile_edit_profile => tr('profile.edit_profile');
  String get profile_choose_picture => tr('profile.choose_picture');
  String get profile_vehicle_data => tr('profile.vehicle_data');
  String get profile_diagnoses => tr('profile.diagnoses');
  String get profile_last_diagnosis => tr('profile.last_diagnosis');
  String get profile_please_login => tr('profile.please_login');
  String get profile_login_message => tr('profile.login_message');
  String get profile_login_now => tr('profile.login_now');
  String get profile_save => tr('profile.save');
  String get profile_saving => tr('profile.saving');
  String get profile_display_name => tr('profile.display_name');
  String get profile_first_name => tr('profile.first_name');
  String get profile_last_name => tr('profile.last_name');
  String get profile_make => tr('profile.make');
  String get profile_model => tr('profile.model');
  String get profile_year => tr('profile.year');
  String get profile_engine_code => tr('profile.engine_code');
  String get profile_displacement => tr('profile.displacement');
  String get profile_power => tr('profile.power');
  String get profile_mileage => tr('profile.mileage');
  String get profile_save_vehicle => tr('profile.save_vehicle');
  String get profile_loading => tr('profile.loading');
  String get profile_required => tr('profile.required');
  String get profile_last_item => tr('profile.last_item');

  // Settings i18n getters
  String get settings_title => tr('settings.title');
  String get settings_general => tr('settings.general');
  String get settings_account => tr('settings.account');
  String get settings_change_email => tr('settings.change_email');
  String get settings_change_password => tr('settings.change_password');
  String get settings_logout => tr('settings.logout');
  String get settings_change_email_title => tr('settings.change_email_title');
  String get settings_change_password_title => tr('settings.change_password_title');
  String get settings_current_email => tr('settings.current_email');
  String get settings_new_email => tr('settings.new_email');
  String get settings_current_password => tr('settings.current_password');
  String get settings_new_password => tr('settings.new_password');
  String get settings_confirm_password => tr('settings.confirm_password');
  String get settings_cancel => tr('settings.cancel');
  String get settings_save => tr('settings.save');

  // Maintenance Overview additional getters
  String get maintenance_upcoming => tr('maintenance.upcoming');
  String get maintenance_overdue_count => tr('maintenance.overdue_count');
  String get maintenance_completed => tr('maintenance.completed');
  String get maintenance_total => tr('maintenance.total');

  // Extended Maintenance getters (matching assets/i18n keys)
  String get maintenance_export_title => tr('maintenance.export_title');
  String get maintenance_export_csv => tr('maintenance.export_csv');
  String get maintenance_total_cost => tr('maintenance.total_cost');

  String get maintenance_stats_upcoming => tr('maintenance.stats_upcoming');
  String get maintenance_stats_overdue => tr('maintenance.stats_overdue');
  String get maintenance_stats_completed => tr('maintenance.stats_completed');
  String get maintenance_stats_total => tr('maintenance.stats_total');

  String get maintenance_categories => tr('maintenance.categories');
  String get maintenance_category_oil_change => tr('maintenance.category_oil_change');
  String get maintenance_category_tire_change => tr('maintenance.category_tire_change');
  String get maintenance_category_brakes => tr('maintenance.category_brakes');
  String get maintenance_category_tuv => tr('maintenance.category_tuv');
  String get maintenance_category_inspection => tr('maintenance.category_inspection');
  String get maintenance_category_battery => tr('maintenance.category_battery');
  String get maintenance_category_filter => tr('maintenance.category_filter');
  String get maintenance_category_insurance => tr('maintenance.category_insurance');
  String get maintenance_category_tax => tr('maintenance.category_tax');
  String get maintenance_category_other => tr('maintenance.category_other');

  String get maintenance_tires_summer => tr('maintenance.tires_summer');
  String get maintenance_tires_winter => tr('maintenance.tires_winter');

  String get maintenance_custom_category_hint => tr('maintenance.custom_category_hint');
  String get maintenance_custom_category_save => tr('maintenance.custom_category_save');
  String get maintenance_custom_category_delete_title => tr('maintenance.custom_category_delete_title');
  String get maintenance_custom_category_delete_message => tr('maintenance.custom_category_delete_message');

  String get maintenance_suggestions_title => tr('maintenance.suggestions_title');

  String get maintenance_photos_title => tr('maintenance.photos_title');
  String get maintenance_photos_add => tr('maintenance.photos_add');
  String get maintenance_documents_title => tr('maintenance.documents_title');
  String get maintenance_documents_upload_pdf => tr('maintenance.documents_upload_pdf');
  
  String get maintenance_notes_title => tr('maintenance.notes_title');
  String get maintenance_notes_hint => tr('maintenance.notes_hint');

  String get maintenance_workshop => tr('maintenance.workshop');
  String get maintenance_workshop_name => tr('maintenance.workshop_name');
  String get maintenance_workshop_name_hint => tr('maintenance.workshop_name_hint');
  String get maintenance_workshop_address => tr('maintenance.workshop_address');
  String get maintenance_workshop_address_hint => tr('maintenance.workshop_address_hint');

  String get maintenance_cost_title => tr('maintenance.cost_title');
  String get maintenance_cost_hint => tr('maintenance.cost_hint');
  String get maintenance_cost_currency => tr('maintenance.cost_currency');

  String get maintenance_mileage_at_maintenance => tr('maintenance.mileage_at_maintenance');

  String get maintenance_notification_enabled => tr('maintenance.notification_enabled');
  String get maintenance_notification_subtitle => tr('maintenance.notification_subtitle');

  // Suggestions
  String get maintenance_suggestion_oil_recommended_title => tr('maintenance.suggestion_oil_recommended_title');
  String get maintenance_suggestion_oil_due_title => tr('maintenance.suggestion_oil_due_title');
  String get maintenance_suggestion_oil_soon_title => tr('maintenance.suggestion_oil_soon_title');
  String get maintenance_suggestion_oil_reason_none => tr('maintenance.suggestion_oil_reason_none');
  String get maintenance_suggestion_oil_reason_since_km => tr('maintenance.suggestion_oil_reason_since_km');

  String get maintenance_season_summer => tr('maintenance.season_summer');
  String get maintenance_season_winter => tr('maintenance.season_winter');
  String get maintenance_suggestion_tire_change_title => tr('maintenance.suggestion_tire_change_title');
  String get maintenance_suggestion_tire_change_reason_months => tr('maintenance.suggestion_tire_change_reason_months');

  String get maintenance_suggestion_tuv_due_title => tr('maintenance.suggestion_tuv_due_title');
  String get maintenance_suggestion_tuv_soon_title => tr('maintenance.suggestion_tuv_soon_title');
  String get maintenance_suggestion_tuv_reason_months => tr('maintenance.suggestion_tuv_reason_months');

  String get maintenance_suggestion_inspection_title => tr('maintenance.suggestion_inspection_title');
  String get maintenance_suggestion_annual_inspection_title => tr('maintenance.suggestion_annual_inspection_title');
  String get maintenance_suggestion_inspection_reason_km => tr('maintenance.suggestion_inspection_reason_km');
  String get maintenance_suggestion_inspection_reason_months => tr('maintenance.suggestion_inspection_reason_months');

  String get maintenance_suggestion_battery_check_title => tr('maintenance.suggestion_battery_check_title');
  String get maintenance_suggestion_battery_reason_months => tr('maintenance.suggestion_battery_reason_months');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['de', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final l = AppLocalizations(locale);
    await l.load();
    return SynchronousFuture<AppLocalizations>(l);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
