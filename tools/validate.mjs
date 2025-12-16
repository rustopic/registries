#!/usr/bin/env node

/**
 * Astralis Registry Validation Script
 * Validates YAML files against JSON schemas and checks referential integrity
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import yaml from 'js-yaml';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

const ajv = new Ajv({ 
  allErrors: true, 
  strict: false,
  validateSchema: false  // Don't validate the schema itself, just use it
});
addFormats(ajv);

let errors = [];
let warnings = [];

// Load all schemas
const schemasDir = path.join(rootDir, 'schemas');
const schemaFiles = fs.readdirSync(schemasDir)
  .filter(f => f.endsWith('.schema.json'))
  .map(f => path.join(schemasDir, f));

// First pass: load all schemas
const schemas = {};
for (const schemaFile of schemaFiles) {
  const schema = JSON.parse(fs.readFileSync(schemaFile, 'utf8'));
  const schemaName = path.basename(schemaFile, '.schema.json');
  schemas[schemaName] = schema;
}

// Second pass: add schemas to AJV (this resolves $ref references)
// Use file paths as schema IDs for proper reference resolution
for (const schemaFile of schemaFiles) {
  const schema = JSON.parse(fs.readFileSync(schemaFile, 'utf8'));
  const schemaName = path.basename(schemaFile, '.schema.json');
  
  // Add schema with its $id if present, otherwise use filename
  if (schema.$id) {
    ajv.addSchema(schema);
  }
  // Also add with short name for convenience
  ajv.addSchema(schema, schemaName);
}

// Helper to read and parse YAML
function readYAML(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    return yaml.load(content);
  } catch (error) {
    errors.push(`Failed to parse YAML ${filePath}: ${error.message}`);
    return null;
  }
}

// Validate against schema
function validateSchema(data, schemaName, filePath) {
  const validate = ajv.getSchema(schemaName);
  if (!validate) {
    errors.push(`Schema ${schemaName} not found`);
    return false;
  }
  
  const valid = validate(data);
  if (!valid) {
    errors.push(`Validation failed for ${filePath}:`);
    validate.errors.forEach(err => {
      errors.push(`  - ${err.instancePath || 'root'}: ${err.message}`);
    });
    return false;
  }
  return true;
}

// Validate manifest
console.log('Validating manifest.yml...');
const manifest = readYAML(path.join(rootDir, 'manifest.yml'));
if (manifest) {
  validateSchema(manifest, 'manifest', 'manifest.yml');
}

// Validate index
console.log('Validating index.yml...');
const index = readYAML(path.join(rootDir, 'index.yml'));
if (index) {
  validateSchema(index, 'index', 'index.yml');
  
  // Check specVersion matches manifest
  if (manifest && index.specVersion !== manifest.specVersion) {
    errors.push(`index.yml specVersion (${index.specVersion}) does not match manifest.yml specVersion (${manifest.specVersion})`);
  }
  
  // Referential integrity: check each game exists
  const gamesDir = path.join(rootDir, 'games');
  for (const game of index.games || []) {
    const gameDir = path.join(rootDir, game.path);
    
    if (!fs.existsSync(gameDir)) {
      errors.push(`Game ${game.id}: directory ${game.path} does not exist`);
      continue;
    }
    
    // Check game.yml exists
    const gameYml = path.join(gameDir, 'game.yml');
    if (!fs.existsSync(gameYml)) {
      errors.push(`Game ${game.id}: game.yml not found`);
    } else {
      const gameData = readYAML(gameYml);
      if (gameData) {
        validateSchema(gameData, 'game', gameYml);
        
        // Check game name matches index (optional check)
        if (gameData.name && gameData.name !== game.name) {
          warnings.push(`Game ${game.id}: game.yml name (${gameData.name}) does not match index name (${game.name})`);
        }
      }
    }
  }
}

// Print results
console.log('\n=== Validation Results ===\n');

if (warnings.length > 0) {
  console.log('Warnings:');
  warnings.forEach(w => console.log(`  ⚠️  ${w}`));
  console.log('');
}

if (errors.length > 0) {
  console.log('Errors:');
  errors.forEach(e => console.log(`  ❌ ${e}`));
  console.log(`\n❌ Validation failed with ${errors.length} error(s)`);
  process.exit(1);
} else {
  console.log('✅ All validations passed!');
  process.exit(0);
}

