# Known Test Performance Issues

## AIIntegration.Tests.ps1 - Hangs when running all tests together

### Symptoms
- Individual `Describe` blocks complete successfully in <1 second
- Discovery phase completes successfully
- Running all tests together causes indefinite hang after ~1 minute
- No error messages or output during hang

### Investigation Results
- Module loads successfully: ✅
- Discovery works: ✅ (52 tests found in 295ms)
- Individual Describe blocks work: ✅
  - Get-FixConfidenceScore: PASS (143ms)
  - Get-MCPContext: PASS (88ms)
  - Invoke-ModelRetraining: PASS (919ms, 8 tests)

### Likely Causes
1. **Resource Exhaustion**: Tests may be consuming too much memory when run together
2. **State Contamination**: Earlier tests may be leaving state that causes later tests to hang
3. **Module Scope Issues**: InModuleScope blocks may be interfering with each other
4. **Async Operations**: Unhandled async operations or runspaces

### Workaround
Skip AIIntegration.Tests.ps1 in CI or run Describe blocks separately

### Action Items
- [ ] Add cleanup in AfterEach/AfterAll blocks
- [ ] Investigate module state between tests
- [ ] Check for unclosed resources (runspaces, file handles)
- [ ] Consider splitting into multiple smaller test files
