#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ========================================
# Smoke Tests: Check tool availability
# ========================================

echo "========================================="
echo "Running Smoke Tests"
echo "========================================="
echo ""

# Create temporary directory for smoke tests
SMOKE_TEST_DIR=$(mktemp -d)
trap "rm -rf $SMOKE_TEST_DIR" EXIT

# Check if a command exists
check_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}✗ FAILED: $cmd not found in PATH${NC}"
        echo "PATH: $PATH"
        return 1
    fi
    echo -e "${GREEN}✓ Found: $cmd${NC}"
    return 0
}

# Check command version
check_version() {
    local cmd=$1
    echo -n "Checking $cmd --version... "
    if ! "$cmd" --version > "$SMOKE_TEST_DIR/${cmd}_version.log" 2>&1; then
        echo -e "${RED}✗ FAILED${NC}"
        echo "Error output:"
        cat "$SMOKE_TEST_DIR/${cmd}_version.log"
        return 1
    fi
    echo -e "${GREEN}✓ PASSED${NC}"
    return 0
}

# Test direct engine compile
test_engine_compile() {
    local engine=$1
    echo -n "Testing $engine direct compile... "
    
    # Create minimal LaTeX test file
    cat > "$SMOKE_TEST_DIR/test-${engine}.tex" <<'EOF'
\documentclass{minimal}
\begin{document}
\end{document}
EOF
    
    # Compile with engine
    if ! "$engine" -interaction=nonstopmode -output-directory="$SMOKE_TEST_DIR" "$SMOKE_TEST_DIR/test-${engine}.tex" > "$SMOKE_TEST_DIR/${engine}_compile.log" 2>&1; then
        echo -e "${RED}✗ FAILED${NC}"
        echo "Error output:"
        cat "$SMOKE_TEST_DIR/${engine}_compile.log"
        return 1
    fi
    echo -e "${GREEN}✓ PASSED${NC}"
    return 0
}

# Test latexmk compile
test_latexmk_compile() {
    echo -n "Testing latexmk -pdf compile... "
    
    # Create minimal LaTeX test file with content
    cat > "$SMOKE_TEST_DIR/test-latexmk.tex" <<'EOF'
\documentclass{article}
\begin{document}
test
\end{document}
EOF
    
    # Compile with latexmk
    if ! latexmk -pdf -interaction=nonstopmode -output-directory="$SMOKE_TEST_DIR" "$SMOKE_TEST_DIR/test-latexmk.tex" > "$SMOKE_TEST_DIR/latexmk_compile.log" 2>&1; then
        echo -e "${RED}✗ FAILED${NC}"
        echo "Error output:"
        cat "$SMOKE_TEST_DIR/latexmk_compile.log"
        return 1
    fi
    echo -e "${GREEN}✓ PASSED${NC}"
    return 0
}

# Run smoke tests
SMOKE_FAILED=false

echo -e "${YELLOW}Checking TeX Engines${NC}"
for engine in pdflatex xelatex lualatex; do
    check_command "$engine" || SMOKE_FAILED=true
    check_version "$engine" || SMOKE_FAILED=true
    test_engine_compile "$engine" || SMOKE_FAILED=true
done
echo ""

echo -e "${YELLOW}Checking latexmk${NC}"
check_command "latexmk" || SMOKE_FAILED=true
check_version "latexmk" || SMOKE_FAILED=true
test_latexmk_compile || SMOKE_FAILED=true
echo ""

if [ "$SMOKE_FAILED" = true ]; then
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}Smoke tests failed. Aborting test suite.${NC}"
    echo -e "${RED}=========================================${NC}"
    exit 1
fi

echo -e "${GREEN}All smoke tests passed!${NC}"
echo ""

# ========================================
# Main Test Suite
# ========================================

# Mapping of test files to their engines
declare -A ENGINE_MAP=(
    ["pdflatex"]="-pdf"
    ["xelatex"]="-pdfxe"
    ["lualatex"]="-pdflua"
)

# Determine engine from filename pattern
get_engine() {
    local filename=$1
    if [[ $filename == *"pdflatex"* ]]; then
        echo "pdflatex"
    elif [[ $filename == *"xelatex"* ]]; then
        echo "xelatex"
    elif [[ $filename == *"lualatex"* ]]; then
        echo "lualatex"
    elif [[ $filename == *"lua"* ]]; then
        echo "lualatex"
    elif [[ $filename == *"xetex"* ]] || [[ $filename == *"xelatex"* ]]; then
        echo "xelatex"
    else
        echo "pdflatex"  # default
    fi
}

# Run a single test
run_test() {
    local test_file=$1
    local engine=$2
    local engine_flag=${ENGINE_MAP[$engine]}
    
    # Extract category (directory name) from test file path
    local category=$(dirname "$test_file")
    # Use absolute path since -cd changes to the source file directory
    local outdir="$PWD/../test-output/$category"
    
    echo -n "Testing $test_file with $engine... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if latexmk -cd -outdir="$outdir" -interaction=nonstopmode "$engine_flag" "$test_file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Create test-output directory structure
rm -rf test-output
mkdir -p test-output/{basic,bibliography,graphics,tikz,fonts}

cd test

echo "========================================="
echo "Running Full Test Suite"
echo "========================================="
echo ""

# Test Basic Engines
echo -e "${YELLOW}Testing Basic Engines${NC}"
for engine in pdflatex xelatex lualatex; do
    run_test "basic/test-${engine}.tex" "$engine" || true
done
echo ""

# Test Bibliography
echo -e "${YELLOW}Testing Bibliography${NC}"
for engine in pdflatex xelatex lualatex; do
    run_test "bibliography/bib-${engine}.tex" "$engine" || true
done
echo ""

# Test Graphics
echo -e "${YELLOW}Testing Graphics${NC}"
for engine in pdflatex xelatex lualatex; do
    run_test "graphics/graphics-${engine}.tex" "$engine" || true
done
echo ""

# Test TikZ
echo -e "${YELLOW}Testing TikZ${NC}"
for engine in pdflatex xelatex lualatex; do
    run_test "tikz/tikz-${engine}.tex" "$engine" || true
done
echo ""

# Test Package-loaded Fonts
echo -e "${YELLOW}Testing Package-loaded Fonts${NC}"
run_test "fonts/fonts-pdflatex.tex" "pdflatex" || true
echo ""

# Clean up all artifacts except PDFs and logs
echo -e "${YELLOW}Cleaning up artifacts...${NC}"
find ../test-output -type f ! -name '*.pdf' ! -name '*.log' -delete

# Print summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
    echo "Failed: $TESTS_FAILED"
fi
echo "========================================="

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi