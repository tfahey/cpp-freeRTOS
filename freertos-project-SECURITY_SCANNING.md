# FreeRTOS Security Scanning with SAST

Comprehensive guide for static application security testing (SAST) using Veracode to detect vulnerabilities in FreeRTOS C code before deployment.

## Overview

This guide covers:

1. **Veracode setup** — API credential generation and environment configuration
2. **SAST packaging** — Preparing compiled artifacts for security analysis
3. **Scanning workflows** — Automated vs. manual testing pipelines
4. **Vulnerability validation** — Understanding Veracode findings
5. **Intentional vulnerabilities** — Testing framework with known flaws for validation

## Why SAST?

FreeRTOS applications run in resource-constrained environments (microcontrollers, embedded systems) where vulnerabilities can have serious consequences:

- **Memory safety**: Buffer overflows, use-after-free, integer overflows
- **Resource leaks**: File descriptors, memory not released
- **Concurrency bugs**: Race conditions in multi-task FreeRTOS apps
- **Cryptographic flaws**: Weak randomness, improper key handling

Veracode SAST detects these patterns statically (without running code), catching issues early in development.

## Veracode Account Setup

### 1. Create Veracode Account

1. Navigate to https://www.veracode.com
2. Sign up for free Developer account (or use existing Enterprise account)
3. Create API credentials in your account dashboard:
   - Login → Account → API Credentials
   - Generate ID and Key
   - **Keep these secret** — treat as passwords

### 2. Retrieve API Credentials

From your Veracode dashboard:
```
API ID:   abc123def456...
API Key:  xyz789uvw012...
```

**⚠️ Security:** Never commit these to git or store in plain text files.

### 3. Set Environment Variables

On your development machine, configure credentials:

```bash
# Add to ~/.bashrc or ~/.zshrc (Linux/macOS)
export VERACODE_API_ID="your-api-id-here"
export VERACODE_API_KEY="your-api-key-here"

# Reload shell
source ~/.bashrc
# or
source ~/.zshrc

# Verify set
echo $VERACODE_API_ID    # Should show your-api-id-here
```

**Alternative: Temporary session only**
```bash
# For this terminal session only (credentials lost on close)
export VERACODE_API_ID="your-api-id-here"
export VERACODE_API_KEY="your-api-key-here"
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
```

## Preprocessing for SAST

Veracode SAST analyzes **preprocessed source code**, not object files or binaries.

### Why Preprocessing?

Compilers perform preprocessing steps before compilation:
1. **Macro expansion**: `#define MAX 100` → replaces `MAX` with `100`
2. **Include resolution**: `#include "config.h"` → inserts file contents
3. **Conditional compilation**: `#ifdef DEBUG` → includes/excludes code

Static analysis needs to see this expanded code to detect vulnerabilities. For example:

**Original source:**
```c
#define BUFFER_SIZE 256
char buffer[BUFFER_SIZE];
strcpy(buffer, user_input);  // Risk: buffer overflow?
```

**After preprocessing:**
```c
char buffer[256];
strcpy(buffer, user_input);  // Analyzer sees concrete size (256)
```

### Generating Preprocessed Files

Add compiler flags to generate `.i` (C) and `.ii` (C++) files:

**In CMakeLists.txt:**
```cmake
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -save-temps=obj")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -save-temps=obj")
```

Or **in build directory after cmake**:
```bash
make CFLAGS="-save-temps=obj" CXXFLAGS="-save-temps=obj"
```

The compiler will generate `.i` files alongside object files:
```
build/
├── CMakeFiles/hello-world.dir/src/
│   ├── main.c.o         # Object file
│   ├── main.c.i         # Preprocessed source
│   ├── tasks.c.o
│   └── tasks.c.i
```

## Automated SAST Workflow

### BUILD_MULTI_ARCH_WITH_SAST.sh

One-command build + SAST scanning:

```bash
# With credentials set in environment
export VERACODE_API_ID="abc123..."
export VERACODE_API_KEY="xyz789..."

# Build for x86-64 + scan
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64

# Build all architectures + scan (only x86-64 can scan due to toolchain)
bash BUILD_MULTI_ARCH_WITH_SAST.sh all
```

**Flow:**
1. Invoke `BUILD_MULTI_ARCH.sh` for specified architecture(s)
2. Compile with `-save-temps=obj` to generate `.i` files
3. Run `veracode package` to package preprocessed source
4. (Optional) Upload to Veracode cloud and run scan
5. Generate local report

### Output Artifacts

After successful run:

```
.
├── freertos-output/
│   └── x86-64/hello-world.elf       # Compiled binary
├── preprocessed-src/
│   ├── main.c.i                     # Preprocessed C source
│   └── tasks.c.i
├── veracode-package/
│   ├── app.zip                      # Packaged for Veracode
│   └── veracode.json                # Build configuration
└── sast-reports/
    ├── results.json                 # Scan results (if uploaded)
    └── summary.txt                  # Human-readable summary
```

### Interpreting Results

**No vulnerabilities found:**
```
✅ Scan Complete
   Status: APPROVED (no flaws)
   High: 0
   Medium: 0
   Low: 0
```

**Vulnerabilities found:**
```
⚠️  Scan Complete
   Status: REQUIRES REVIEW
   High: 2
   Medium: 5
   Low: 3

Findings:
1. CWE-120: Buffer Overflow
   File: src/main.c, line 45
   Severity: High
   Description: strcpy() used with unbounded user input
```

## Manual SAST Workflow (No Cloud Upload)

If you don't want to upload to Veracode cloud, analyze locally:

```bash
# Build only (no Veracode API credentials needed)
bash BUILD_MULTI_ARCH.sh x86-64

# Manually package for analysis
cd /path/to/project
veracode package \
  --source preprocessed-src/ \
  --target veracode-package/ \
  --no-upload

# Output is in veracode-package/app.zip
# You can review this manually or upload later
```

## Intentional Vulnerability Testing

To validate that your SAST setup detects known issues, add intentional vulnerabilities:

### Common CWE Patterns

#### CWE-120: Buffer Overflow (Classic)

**In src/main.c:**
```c
void vulnerable_buffer() {
    char buffer[10];
    strcpy(buffer, user_input);  // ❌ Unbounded copy
}
```

**Fix:**
```c
void safe_buffer() {
    char buffer[10];
    strncpy(buffer, user_input, sizeof(buffer) - 1);  // ✅ Bounded
}
```

**Expected finding:** Veracode flags `strcpy()` as high-severity buffer overflow risk

#### CWE-125: Out-of-Bounds Read

**Vulnerable:**
```c
int read_user_array(int index) {
    int safe_array[5] = {1, 2, 3, 4, 5};
    return safe_array[index];  // ❌ Index not validated
}
```

**Safe:**
```c
int read_user_array(int index) {
    int safe_array[5] = {1, 2, 3, 4, 5};
    if (index < 0 || index >= 5) return -1;  // ✅ Validate
    return safe_array[index];
}
```

**Expected finding:** Array index not validated

#### CWE-190: Integer Overflow

**Vulnerable:**
```c
void allocate_buffer(int size) {
    char *buf = malloc(size);  // ❌ Size not validated
}

allocate_buffer(-1);  // Wraps to huge positive, DoS
```

**Safe:**
```c
void allocate_buffer(int size) {
    if (size <= 0 || size > MAX_BUFFER) return NULL;  // ✅ Validate
    char *buf = malloc(size);
}
```

**Expected finding:** Integer overflow risk in memory allocation

#### CWE-400: Uncontrolled Resource Consumption

**Vulnerable (FreeRTOS-specific):**
```c
void task_leak_memory(void *pvParameters) {
    while (1) {
        char *mem = pvPortMalloc(100);  // ❌ Never freed
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
```

**Safe:**
```c
void task_no_leak(void *pvParameters) {
    while (1) {
        char *mem = pvPortMalloc(100);
        // ... use mem ...
        vPortFree(mem);  // ✅ Cleanup
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
```

**Expected finding:** Memory not freed in loop

#### CWE-563: Assignment to Self (Logic Error)

**Vulnerable:**
```c
int config_value = get_config();
config_value = config_value;  // ❌ Pointless assignment
```

**Safe:**
```c
int local_config = get_config();
int global_config;
global_config = local_config;  // ✅ Intent clear
```

**Expected finding:** Assignment to self has no effect

### FreeRTOS-Specific Vulnerabilities

#### Improper Task Synchronization

**Vulnerable:**
```c
static int shared_counter = 0;

void increment_task(void *pvParameters) {
    while (1) {
        shared_counter++;  // ❌ Race condition without mutex
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
```

**Safe:**
```c
static StaticMutex_t counter_mutex;
static int shared_counter = 0;

void increment_task(void *pvParameters) {
    while (1) {
        xSemaphoreTake(counter_mutex, portMAX_DELAY);
        shared_counter++;  // ✅ Protected by mutex
        xSemaphoreGive(counter_mutex);
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
```

**Expected finding:** Shared resource access without synchronization

#### Incorrect Interrupt Handling

**Vulnerable:**
```c
void ISR_handler(void) {
    // ❌ Calling blocking FreeRTOS functions from ISR
    xQueueSend(queue, &data, portMAX_DELAY);  // Illegal!
}
```

**Safe:**
```c
void ISR_handler(void) {
    // ✅ Use ISR-safe variant
    BaseType_t higher_priority_woken = pdFALSE;
    xQueueSendFromISR(queue, &data, &higher_priority_woken);
    portYIELD_FROM_ISR(higher_priority_woken);
}
```

**Expected finding:** Unsafe blocking call from interrupt context

## Setting Up Test Suite

To validate that scanning works:

### 1. Create Test Source

**src/vulnerability_tests.c:**
```c
#include <string.h>
#include <stdlib.h>

// Intentional vulnerabilities for testing SAST setup

void vulnerable_strcpy(char *user_input) {
    char buffer[10];
    strcpy(buffer, user_input);  // CWE-120: Buffer Overflow
}

void vulnerable_array_access(int *array, int index) {
    return array[index];  // CWE-125: Out-of-bounds (index not validated)
}

void vulnerable_malloc(int size) {
    char *ptr = malloc(size);  // CWE-190: Integer overflow possible
}

void vulnerable_loop_leak(void) {
    for (int i = 0; i < 100; i++) {
        char *mem = malloc(100);  // CWE-400: Memory not freed in loop
    }
}

void vulnerable_self_assign(void) {
    int x = 5;
    x = x;  // CWE-563: Assignment to self
}
```

### 2. Add to Build

**CMakeLists.txt:**
```cmake
add_executable(hello-world
  src/main.c
  src/tasks/example_task.c
  src/vulnerability_tests.c  # Include test vulnerabilities
)
```

### 3. Scan and Validate

```bash
export VERACODE_API_ID="..."
export VERACODE_API_KEY="..."

bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64

# Check results
cat sast-reports/summary.txt
```

**Expected output shows:** CWE-120 (buffer overflow), CWE-125, CWE-190, CWE-400, CWE-563

### 4. Remove After Testing

Once you've validated scanning works, remove or comment out vulnerabilities:

**src/vulnerability_tests.c:**
```c
// Commented out after validation
/*
void vulnerable_strcpy(char *user_input) {
    char buffer[10];
    strcpy(buffer, user_input);  // CWE-120: Buffer Overflow
}
*/
```

## Scanning Multiple Architectures

### x86-64 Only

Only x86-64 containers have Veracode CLI installed (not available for ARM):

```bash
# ✅ This works (has Veracode CLI)
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64

# ❌ This fails (ARM containers don't have Veracode CLI)
bash BUILD_MULTI_ARCH_WITH_SAST.sh arm-cortex-m4
```

### Workaround: Generate Preprocessed, Scan Later

```bash
# Build for ARM (generates preprocessed .i files)
bash BUILD_MULTI_ARCH.sh arm-cortex-m4
# Preprocessed files now in preprocessed-src/

# In x86-64 container, package and scan
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 shell

cd /home/builder/project
veracode package --source preprocessed-src/ --target veracode-package/

# Submit for scanning with credentials
veracode scan upload --source veracode-package/app.zip \
  --api-id "$VERACODE_API_ID" \
  --api-key "$VERACODE_API_KEY"

exit
```

## Continuous Integration (CI)

### GitHub Actions Example

**.github/workflows/sast-scan.yml:**
```yaml
name: SAST Scan

on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and Scan
        env:
          VERACODE_API_ID: ${{ secrets.VERACODE_API_ID }}
          VERACODE_API_KEY: ${{ secrets.VERACODE_API_KEY }}
        run: |
          bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
      
      - name: Upload Report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: sast-reports
          path: sast-reports/
```

### Setup GitHub Secrets

1. In repo: Settings → Secrets and Variables → Actions
2. Add `VERACODE_API_ID` secret
3. Add `VERACODE_API_KEY` secret
4. Commit workflow file
5. On next push, workflow runs automatically

## Troubleshooting

### "Veracode CLI not found"

**Error:** `Command 'veracode' not found`

**Cause:** Running on ARM architecture or Veracode CLI not installed

**Solution:** Use x86-64 container or build only
```bash
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64  # ✅ Has CLI
bash BUILD_MULTI_ARCH.sh arm-cortex-m4     # ✅ Build only, scan with x86-64
```

### "Invalid API credentials"

**Error:** `401 Unauthorized` or `Invalid API key`

**Cause:** API credentials not set or incorrect

**Solution:** Verify credentials
```bash
echo $VERACODE_API_ID
echo $VERACODE_API_KEY

# Re-export with correct values
export VERACODE_API_ID="correct-id"
export VERACODE_API_KEY="correct-key"

bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
```

### "No artifacts found"

**Error:** `Successfully ran packager tool, but no artifacts identified`

**Cause:** Preprocessed source files not generated

**Solution:** Rebuild with `-save-temps=obj`
```bash
bash CONTAINER_MANAGER.sh x86-64 shell
cd build
rm -rf CMakeFiles/  # Force recompile
cmake .. -DCMAKE_CXX_FLAGS="-save-temps=obj"
make
ls preprocessed-src/*.i  # Verify .i files exist
```

### Scan takes a long time

**Issue:** Veracode upload/scan running slow

**Expected:** Initial upload ~2-5 min, scan 5-10 min (depends on code size and Veracode queue)

**Patience:** Veracode may queue scans during peak times

### Report shows false positives

**Issue:** Findings that aren't actual vulnerabilities

**Solution:**
1. Review finding in Veracode dashboard
2. If false positive, mark as "Approved" in dashboard
3. Veracode learns from feedback

## Veracode Dashboard

### Viewing Scan Results

1. Login to https://analysis.veracode.com
2. Select application
3. View findings by:
   - **Severity**: High, Medium, Low
   - **CWE**: Type of vulnerability
   - **Status**: New, Fixed, Approved

### Tracking Over Time

- **Graphs**: Vulnerability trend over time
- **Reports**: Export findings as PDF/CSV
- **Policies**: Set pass/fail criteria (e.g., "fail if >5 High")

## Best Practices

1. **Scan before commits**: Run SAST locally before pushing
   ```bash
   bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
   # Review sast-reports/
   git commit -m "..."
   git push
   ```

2. **Fix high-severity findings first**: Prioritize CWE-120 (buffer overflow), CWE-125 (out-of-bounds)

3. **Use safe alternatives**:
   - Replace `strcpy()` with `strncpy()` or `strlcpy()`
   - Replace `sprintf()` with `snprintf()`
   - Validate all user input before use

4. **Keep toolchain updated**: Veracode releases new rules regularly

5. **Document intentional decisions**: If you accept a risk, document why

## CWE Reference for Embedded Systems

| CWE | Title | Risk | Fix |
|---|---|---|---|
| CWE-120 | Buffer Overflow | High | Use bounded functions (strncpy, snprintf) |
| CWE-125 | Out-of-Bounds Read | High | Validate array indices |
| CWE-190 | Integer Overflow | Medium | Check int size before operations |
| CWE-400 | Uncontrolled Resource | Medium | Free allocated resources in all paths |
| CWE-401 | Memory Leak | Low | Ensure cleanup in error paths |
| CWE-562 | Return Value Not Checked | Low | Check return codes of malloc, fopen, etc. |
| CWE-563 | Assignment to Self | Low | Remove pointless assignments |

## Next Steps

1. Setup Veracode account and API credentials
2. Read **README.md** for quick start
3. Read **CONTAINER_USAGE.md** for manual workflow
4. Run first scan: `bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64`
5. Review findings in Veracode dashboard
