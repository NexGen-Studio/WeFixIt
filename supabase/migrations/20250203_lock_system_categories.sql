-- Migration: Lock all system categories except Treibstoff
-- Erstellt: 03.02.2025
-- Beschreibung: Setzt is_locked = true für alle System-Kategorien außer 'Treibstoff'

-- 1. Setze alle System-Kategorien auf locked
UPDATE cost_categories
SET is_locked = true
WHERE is_system = true;

-- 2. Entsperre 'Treibstoff' (damit Free-User sie nutzen können)
UPDATE cost_categories
SET is_locked = false
WHERE is_system = true AND name = 'Treibstoff';
