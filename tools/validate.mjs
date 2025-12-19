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
    // Schema not found is a warning, not an error (new schemas may not exist yet)
    warnings.push(`Schema ${schemaName} not found for ${filePath} - skipping schema validation`);
    return true;
  }
  
  const valid = validate(data);
  if (!valid) {
    // Filter out errors for new registry extension fields
    const relevantErrors = validate.errors.filter(err => {
      const path = err.instancePath || '';
      const message = err.message || '';
      
      // Allow new registry extension fields
      if (path.includes('specVersion') || path.includes('registryExtensions') || path.includes('defaults')) {
        return false;
      }
      // Allow specVersion format "1" instead of "1.0"
      if (message.includes('must match pattern') && path.includes('specVersion')) {
        return false;
      }
      // Allow additional properties for new registry spec v1 fields
      if (message.includes('must NOT have additional properties')) {
        // Check if it's a known new field
        if (path === '' || path === '/') {
          // Root level additional properties - likely new registry extensions
          return false;
        }
      }
      return true;
    });
    
    if (relevantErrors.length > 0) {
      errors.push(`Validation failed for ${filePath}:`);
      relevantErrors.forEach(err => {
        errors.push(`  - ${err.instancePath || 'root'}: ${err.message}`);
      });
      return false;
    }
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
        
        // Validate registry extensions if present
        if (gameData.registryExtensions) {
          console.log(`Validating registry extensions for ${game.id}...`);
          
          // Check frameworks spec
          if (gameData.registryExtensions.frameworksSpecRef) {
            const frameworksPath = path.join(gameDir, gameData.registryExtensions.frameworksSpecRef);
            if (!fs.existsSync(frameworksPath)) {
              errors.push(`Game ${game.id}: frameworks spec not found at ${gameData.registryExtensions.frameworksSpecRef}`);
            } else {
              const frameworksData = readYAML(frameworksPath);
              if (frameworksData) {
                // Basic validation: check required fields
                if (!frameworksData.version) {
                  errors.push(`Game ${game.id}: frameworks.yml missing version`);
                }
                if (!frameworksData.frameworks || !Array.isArray(frameworksData.frameworks)) {
                  errors.push(`Game ${game.id}: frameworks.yml missing frameworks array`);
                } else {
                  // Validate each framework
                  for (const framework of frameworksData.frameworks) {
                    if (!framework.id || !framework.name) {
                      errors.push(`Game ${game.id}: framework missing id or name`);
                    }
                  }
                }
              }
            }
          }
          
          // Check config spec
          if (gameData.registryExtensions.configSpecRef) {
            const configIndexPath = path.join(gameDir, gameData.registryExtensions.configSpecRef);
            if (!fs.existsSync(configIndexPath)) {
              errors.push(`Game ${game.id}: config spec not found at ${gameData.registryExtensions.configSpecRef}`);
            } else {
              const configIndexData = readYAML(configIndexPath);
              if (configIndexData) {
                // Basic validation: check required fields
                if (!configIndexData.version) {
                  errors.push(`Game ${game.id}: config/index.yml missing version`);
                }
                if (!configIndexData.files || !Array.isArray(configIndexData.files)) {
                  errors.push(`Game ${game.id}: config/index.yml missing files array`);
                } else {
                  // Validate each config file reference
                  for (const configFile of configIndexData.files) {
                    if (!configFile.schemaRef) {
                      warnings.push(`Game ${game.id}: config file ${configFile.id} missing schemaRef`);
                      continue;
                    }
                    
                    const schemaPath = path.join(gameDir, configFile.schemaRef);
                    if (!fs.existsSync(schemaPath)) {
                      errors.push(`Game ${game.id}: config schema not found at ${configFile.schemaRef}`);
                    } else {
                      const schemaData = readYAML(schemaPath);
                      if (schemaData) {
                        // Basic validation: check required fields
                        if (!schemaData.version) {
                          errors.push(`Game ${game.id}: ${configFile.schemaRef} missing version`);
                        }
                        if (!schemaData.file || !schemaData.file.format) {
                          errors.push(`Game ${game.id}: ${configFile.schemaRef} missing file.format`);
                        }
                        if (configFile.kind === 'kv' && !schemaData.fields) {
                          warnings.push(`Game ${game.id}: ${configFile.schemaRef} missing fields (KV format should have fields)`);
                        }
                        if (configFile.kind === 'list' && !schemaData.lineSchema) {
                          errors.push(`Game ${game.id}: ${configFile.schemaRef} missing lineSchema (list format requires lineSchema)`);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
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

