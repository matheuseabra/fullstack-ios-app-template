/** @type {import('ts-jest').JestConfigWithTsJest} */
export default {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  extensionsToTreatAsEsm: ['.ts'],
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
  },
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        useESM: true,
        tsconfig: './tsconfig.json',
        // Suppress TS151002: NodeNext + ts-jest compatibility warning
        diagnostics: { ignoreCodes: [151002] },
      },
    ],
  },
  testMatch: ['**/tests/**/*.test.ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/types/**'],
  coverageDirectory: 'coverage',
  // Set required env vars before any module is loaded (env.ts validates on import).
  // Uses .cjs to stay out of the ESM transform pipeline.
  setupFiles: ['<rootDir>/tests/env.setup.cjs'],
}
