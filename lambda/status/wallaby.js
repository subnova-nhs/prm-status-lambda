/* ignore file coverage: just a config file */
module.exports = () => {
    return {
      files: [
        '*.js', 
        '!*.test.js'
      ],
      tests: ['*.test.js'],
      hints: {
        ignoreCoverageForFile: /ignore file coverage/,
        ignoreCoverage: /ignore coverage/
      },
      env: {
        type: 'node',
        runner: 'node'
      },
  
      testFramework: 'jest'
    };
  };
  