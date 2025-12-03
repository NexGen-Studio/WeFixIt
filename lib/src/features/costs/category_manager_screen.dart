import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../i18n/app_localizations.dart';
import '../../services/category_service.dart';
import '../../models/cost_category.dart';

/// Screen zum Verwalten von Kategorien (Custom)
class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final CategoryService _categoryService = CategoryService();
  
  List<CostCategory> _systemCategories = [];
  List<CostCategory> _customCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Loading categories...');
      final system = await _categoryService.fetchSystemCategories();
      final custom = await _categoryService.fetchCustomCategories();
      
      print('✅ Loaded ${system.length} system categories');
      print('✅ Loaded ${custom.length} custom categories');

      if (mounted) {
        setState(() {
          _systemCategories = system;
          _customCategories = custom;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading categories: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Kategorien: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddCategoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryDialog(
        onSave: (name, iconName, colorHex) async {
          final category = await _categoryService.createCustomCategory(
            name: name,
            iconName: iconName,
            colorHex: colorHex,
          );
          
          return category != null;
        },
      ),
    );
    
    if (result == true) {
      _loadCategories();
    }
  }

  void _showEditCategoryDialog(CostCategory category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryDialog(
        category: category,
        onSave: (name, iconName, colorHex) async {
          final updated = await _categoryService.updateCustomCategory(
            id: category.id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
          );
          
          return updated != null;
        },
      ),
    );
    
    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(CostCategory category) async {
    final t = AppLocalizations.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151C23),
        title: Text(
          t.tr('costs.delete_category'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          t.tr('costs.delete_category_message'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.tr('common.delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _categoryService.deleteCustomCategory(category.id);
      
      if (success) {
        _loadCategories();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.tr('costs.cannot_delete_category')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.tr('costs.manage_categories'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFFB129)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Standard-Kategorien
                Text(
                  t.tr('costs.standard_categories'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ..._systemCategories.map((cat) => _buildCategoryTile(cat, isSystem: true)),
                
                const SizedBox(height: 24),
                
                // Custom-Kategorien
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.tr('costs.custom_categories'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(t.tr('costs.add_category')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB129),
                        side: const BorderSide(color: Color(0xFFFFB129)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_customCategories.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151C23),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        t.tr('costs.no_custom_categories'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  ..._customCategories.map((cat) => _buildCategoryTile(cat, isSystem: false)),
              ],
            ),
    );
  }

  Widget _buildCategoryTile(CostCategory category, {required bool isSystem}) {
    final t = AppLocalizations.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CostCategory.hexToColor(category.colorHex).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CostCategory.hexToColor(category.colorHex).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CostCategory.getIconData(category.iconName),
              color: CostCategory.hexToColor(category.colorHex),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isSystem) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
              onPressed: () => _showEditCategoryDialog(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteCategory(category),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Dialog zum Erstellen/Bearbeiten von Kategorien
// ============================================================================

class _CategoryDialog extends StatefulWidget {
  final CostCategory? category; // null = Neu erstellen
  final Future<bool> Function(String name, String iconName, String colorHex) onSave;

  const _CategoryDialog({
    Key? key,
    this.category,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedIcon = 'star';
  String _selectedColor = '#FF9800';
  bool _isSaving = false;

  final List<String> _availableIcons = [
    'star', 'favorite', 'home', 'work', 'event', 'person',
    'emoji_transportation', 'directions_car', 'local_shipping',
    'two_wheeler', 'electric_car', 'settings',
  ];

  final List<String> _availableColors = [
    '#E53935', '#D32F2F', '#C62828', // Rot
    '#F8AD20', '#FF9800', '#FF6F00', // Orange/Gelb
    '#4CAF50', '#388E3C', '#2E7D32', // Grün
    '#2196F3', '#1976D2', '#1565C0', // Blau
    '#9C27B0', '#7B1FA2', '#6A1B9A', // Lila
    '#795548', '#5D4037', '#4E342E', // Braun
    '#607D8B', '#455A64', '#37474F', // Grau
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.iconName;
      _selectedColor = widget.category!.colorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      backgroundColor: const Color(0xFF151C23),
      insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // 90% Breite
      contentPadding: const EdgeInsets.all(0),
      title: Text(
        widget.category != null 
            ? t.tr('costs.edit_category')
            : t.tr('costs.add_category'),
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Name
            Text(
              t.tr('costs.category_name'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: t.tr('costs.category_name_hint'),
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A2028),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Icon-Auswahl
            Text(
              t.tr('costs.select_icon'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? CostCategory.hexToColor(_selectedColor).withOpacity(0.2)
                          : const Color(0xFF1A2028),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? CostCategory.hexToColor(_selectedColor)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      CostCategory.getIconData(icon),
                      color: isSelected 
                          ? CostCategory.hexToColor(_selectedColor)
                          : Colors.white70,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Farb-Auswahl
            Text(
              t.tr('costs.select_color'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CostCategory.hexToColor(color),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.tr('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () async {
            if (_nameController.text.isEmpty) return;
            
            setState(() => _isSaving = true);
            
            try {
              final success = await widget.onSave(
                _nameController.text,
                _selectedIcon,
                _selectedColor,
              );
              
              if (success && mounted) {
                Navigator.pop(context, true);
              }
            } finally {
              if (mounted) {
                setState(() => _isSaving = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB129),
            foregroundColor: Colors.black,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                )
              : Text(t.tr('common.save')),
        ),
      ],
    );
  }
}
