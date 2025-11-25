import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cost_category.dart';

/// Service für Kostenkategorien (Standard + Custom)
class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Alle Kategorien abrufen (System + eigene Custom)
  Future<List<CostCategory>> fetchAllCategories() async {
    try {
      final response = await _supabase
          .from('cost_categories')
          .select()
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => CostCategory.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Nur System-Kategorien abrufen
  Future<List<CostCategory>> fetchSystemCategories() async {
    try {
      final response = await _supabase
          .from('cost_categories')
          .select()
          .eq('is_system', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => CostCategory.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching system categories: $e');
      return [];
    }
  }

  /// Nur eigene Custom-Kategorien abrufen
  Future<List<CostCategory>> fetchCustomCategories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('cost_categories')
          .select()
          .eq('user_id', userId)
          .eq('is_system', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CostCategory.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching custom categories: $e');
      return [];
    }
  }

  /// Einzelne Kategorie abrufen
  Future<CostCategory?> fetchCategoryById(String id) async {
    try {
      final response = await _supabase
          .from('cost_categories')
          .select()
          .eq('id', id)
          .single();

      return CostCategory.fromJson(response);
    } catch (e) {
      print('Error fetching category: $e');
      return null;
    }
  }

  /// Custom-Kategorie erstellen
  Future<CostCategory?> createCustomCategory({
    required String name,
    required String iconName,
    required String colorHex,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('cost_categories')
          .insert({
            'user_id': userId,
            'name': name,
            'icon_name': iconName,
            'color_hex': colorHex,
            'is_system': false,
            'sort_order': 100, // Custom categories am Ende
          })
          .select()
          .single();

      return CostCategory.fromJson(response);
    } catch (e) {
      print('Error creating custom category: $e');
      return null;
    }
  }

  /// Custom-Kategorie aktualisieren
  Future<CostCategory?> updateCustomCategory({
    required String id,
    String? name,
    String? iconName,
    String? colorHex,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (iconName != null) updates['icon_name'] = iconName;
      if (colorHex != null) updates['color_hex'] = colorHex;

      if (updates.isEmpty) return null;

      final response = await _supabase
          .from('cost_categories')
          .update(updates)
          .eq('id', id)
          .eq('user_id', userId)
          .eq('is_system', false)
          .select()
          .single();

      return CostCategory.fromJson(response);
    } catch (e) {
      print('Error updating custom category: $e');
      return null;
    }
  }

  /// Custom-Kategorie löschen (nur wenn keine Einträge vorhanden)
  Future<bool> deleteCustomCategory(String id) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Prüfen, ob noch Einträge mit dieser Kategorie existieren
      final countResponse = await _supabase
          .from('vehicle_costs')
          .select('id')
          .eq('category_id', id);

      final count = (countResponse as List).length;
      if (count > 0) {
        throw Exception('Cannot delete category with existing entries');
      }

      // Löschen
      await _supabase
          .from('cost_categories')
          .delete()
          .eq('id', id)
          .eq('user_id', userId)
          .eq('is_system', false);

      return true;
    } catch (e) {
      print('Error deleting custom category: $e');
      return false;
    }
  }

  /// Kategorie nach Name finden (für System-Kategorien)
  Future<CostCategory?> findSystemCategoryByName(String name) async {
    try {
      final response = await _supabase
          .from('cost_categories')
          .select()
          .eq('name', name)
          .eq('is_system', true)
          .maybeSingle();

      if (response == null) return null;
      return CostCategory.fromJson(response);
    } catch (e) {
      print('Error finding system category: $e');
      return null;
    }
  }
}
