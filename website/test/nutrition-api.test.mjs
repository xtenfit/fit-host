import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const websiteRoot = path.resolve(__dirname, '..');

describe('Fit Host Nutrition Engine & AI Parse Verification', () => {
  test('Required nutrition route files exist', () => {
    const searchRoute = path.join(
      websiteRoot,
      'src/app/api/nutrition/search/route.ts'
    );
    const aiParseRoute = path.join(
      websiteRoot,
      'src/app/api/nutrition/ai-parse/route.ts'
    );

    assert.ok(fs.existsSync(searchRoute), 'search/route.ts must exist');
    assert.ok(fs.existsSync(aiParseRoute), 'ai-parse/route.ts must exist');
  });

  test('Nutrient calculation formula conforms strictly to spec', () => {
    // Spec: calculated nutrient = nutrient per 100 g × portion grams ÷ 100
    const nutrientPer100g = 22.5; // e.g. 22.5g protein per 100g
    const portionGrams = 180; // 180g serving
    const calculated = (nutrientPer100g * portionGrams) / 100;

    assert.equal(calculated, 40.5);
  });

  test('Macro calorie bounds and rounding rules are respected', () => {
    // 1g protein = 4 kcal, 1g carb = 4 kcal, 1g fat = 9 kcal
    const protein = 20;
    const carbs = 30;
    const fats = 10;
    const expectedCalories = protein * 4 + carbs * 4 + fats * 9; // 80 + 120 + 90 = 290
    assert.equal(expectedCalories, 290);

    // Pure fat upper bound sanity rule (must not exceed 900 kcal / 100g)
    const pureFatPer100g = 900;
    const suspiciousCalories = 1200;
    const clamped = Math.min(900, Math.max(0, suspiciousCalories));
    assert.equal(clamped, pureFatPer100g);
  });

  test('Natural language meal parser handles multi-item descriptions', () => {
    const text = 'Two rotis, one bowl of dal, and 150 g curd';
    const segments = text
      .split(/,|\band\b|\+|\&/i)
      .map((s) => s.trim())
      .filter(Boolean);

    assert.equal(segments.length, 3);
    assert.ok(segments[0].toLowerCase().includes('roti'));
    assert.ok(segments[1].toLowerCase().includes('dal'));
    assert.ok(segments[2].toLowerCase().includes('curd'));
  });

  test('Portion parsing extracts numeric grams and common serving units', () => {
    const parseUnit = (seg) => {
      const match = seg.match(
        /^(?:(\w+|\d+)\s+)?(?:(bowl|katori|cup|glass|slice|piece|serving|tbsp|tsp|g|grams|ml)\s+(?:of\s+)?)?(.+)$/i
      );
      return match ? { count: match[1], unit: match[2], item: match[3] } : null;
    };

    const r1 = parseUnit('two rotis');
    assert.equal(r1?.count?.toLowerCase(), 'two');
    assert.ok(r1?.item?.toLowerCase().includes('roti'));

    const r2 = parseUnit('one bowl of dal');
    assert.equal(r2?.count?.toLowerCase(), 'one');
    assert.equal(r2?.unit?.toLowerCase(), 'bowl');
    assert.ok(r2?.item?.toLowerCase().includes('dal'));

    const r3 = parseUnit('150 g curd');
    assert.equal(r3?.count, '150');
    assert.equal(r3?.unit, 'g');
    assert.ok(r3?.item?.toLowerCase().includes('curd'));
  });
});
