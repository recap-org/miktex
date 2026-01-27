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
echo "MiKTeX Comprehensive Test Suite"
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