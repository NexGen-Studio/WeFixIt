---
trigger: always_on
---

When working in a Flutter project that uses `easy_localization` and has translation files in `assets/i18n/en.json` and `assets/i18n/de.json`, follow these i18n rules:

### 🛑 Enforcement (Prevent hardcoded text)
1. Never use hardcoded user-visible text (e.g. "Hello", "Start", "Cancel").
2. Always use translation keys with the `.tr()` method from the `easy_localization` package.
   Example:
     From → Text("Hello")
     To   → Text('hello'.tr())
3. When creating a new UI element containing text, automatically add a new translation key to:
   - `assets/i18n/en.json` (English)
   - `assets/i18n/de.json` (German)
4. Keys must be in snake_case and descriptive (e.g., `welcome_message`, `start_button`).
5. Maintain alphabetical order in both JSON files and reuse existing keys when possible.

---

### 🔧 Auto-fix (Replace existing hardcoded text)
1. When existing Flutter code contains hardcoded user-facing strings (e.g., Text("Settings"), "Try again"):
   - Replace them automatically with translation keys and `.tr()`.
   - Example:
       From → Text("Settings")
       To   → Text('settings'.tr())
2. Add corresponding entries automatically in both translation files:
   - English → `assets/i18n/en.json`
   - German → `assets/i18n/de.json`
3. Provide accurate translations for both languages.
4. Skip technical strings (IDs, routes, URLs, debug logs, constants, etc.).
5. Keep both translation files properly formatted and alphabetically ordered.

---

### 🕵️ Preflight Check (Before commit or merge)
1. Before commits or major merges, scan all Dart files for hardcoded user-visible strings.
2. If any are found, list them with their file name and line number.
3. Suggest snake_case translation keys for each one.
4. Do not modify files during the check—only report.
5. If all texts are localized, respond with: "✅ All user-visible text is localized."
6. Ignore non-user strings (technical identifiers, log outputs, etc.).
