module.exports = {
  testEnvironment: 'node',
  collectCoverage: false,
  coverageReporters: ['text', 'lcov'],
  testMatch: ['**/test/**/*.test.js'],
  verbose: true,
  forceExit: true,
  detectOpenHandles: true,
  setupFilesAfterEnv: ['<rootDir>/test/setup.js']
};