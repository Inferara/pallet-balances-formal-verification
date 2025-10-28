#!/bin/bash

# Usage: ./reorder_wat.sh input.wat output.wat "index_list"
# Example: ./reorder_wat.sh github.wat local.wat "18,19,20,21,22,23,24,25,26,28,27,29,30,31,33,32,34,35,58,56,42,43,44,45,46,47,48,49,50,51,52,53,54,55,57,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86"
# The index list should contain absolute function indexes (including imports offset)

set -e

INPUT_FILE="$1"
OUTPUT_FILE="$2"
INDEX_LIST="$3"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ] || [ -z "$INDEX_LIST" ]; then
    echo "Usage: $0 <input.wat> <output.wat> <index_list>"
    echo "Example: $0 input.wat output.wat \"18,19,20,21,22,23,24,25,26,28,27,...\""
    echo ""
    echo "The index list should contain the absolute function indexes in the desired order,"
    echo "starting from the first non-imported function."
    exit 1
fi

# Convert comma-separated index list to array
IFS=',' read -ra NEW_ORDER <<< "$INDEX_LIST"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Count imported functions to know the offset
IMPORT_COUNT=$(grep -c "^  (import.*func" "$INPUT_FILE" || true)

echo "Found $IMPORT_COUNT imported functions"
echo "Non-imported functions start at index $IMPORT_COUNT"

# Validate that index list starts at IMPORT_COUNT
FIRST_IDX="${NEW_ORDER[0]}"
if [ "$FIRST_IDX" -ne "$IMPORT_COUNT" ]; then
    echo "Error: Index list should start with $IMPORT_COUNT (first non-imported function)"
    echo "Your list starts with: $FIRST_IDX"
    exit 1
fi

# Build mapping: old_absolute_index -> new_absolute_index
declare -A OLD_TO_NEW
for new_position in "${!NEW_ORDER[@]}"; do
    old_abs_idx="${NEW_ORDER[$new_position]}"
    new_abs_idx=$((IMPORT_COUNT + new_position))
    OLD_TO_NEW[$old_abs_idx]=$new_abs_idx
done

# Extract the header (everything before first function)
awk '/^  \(func / {exit} {print}' "$INPUT_FILE" > "$TEMP_DIR/header.wat"

# Extract individual functions with their absolute indexes
awk -v import_count="$IMPORT_COUNT" '
BEGIN { func_num = -1; in_func = 0; depth = 0 }
/^  \(func / {
    func_num++
    abs_idx = import_count + func_num
    in_func = 1
    depth = 1
    file = sprintf("'"$TEMP_DIR"'/func_%d.wat", abs_idx)
    print > file
    next
}
in_func {
    print >> file
    # Count parentheses to track nesting depth
    for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c == "(") depth++
        if (c == ")") {
            depth--
            if (depth == 0) {
                in_func = 0
                break
            }
        }
    }
}
' "$INPUT_FILE"

# Extract the footer (everything after last function)
awk '
BEGIN { in_func = 0; depth = 0; func_done = 0 }
/^  \(func / { in_func = 1; depth = 1; next }
in_func {
    for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c == "(") depth++
        if (c == ")") {
            depth--
            if (depth == 0) {
                in_func = 0
                func_done = 1
                next
            }
        }
    }
    next
}
func_done { print }
' "$INPUT_FILE" > "$TEMP_DIR/footer.wat"

# Create Python script for updating call instructions
cat > "$TEMP_DIR/update_calls.py" <<'PYTHON_SCRIPT'
import sys
import re

old_to_new = {}
import_count = int(sys.argv[1])

# Read mapping from stdin (format: old_idx new_idx per line)
for line in sys.stdin:
    if line.strip():
        old, new = map(int, line.strip().split())
        old_to_new[old] = new

# Read function content from file
with open(sys.argv[2], 'r') as f:
    content = f.read()

# Replace call instructions
def replace_call(match):
    call_idx = int(match.group(1))
    # Only update calls to non-imported functions
    if call_idx >= import_count:
        if call_idx in old_to_new:
            return f"call {old_to_new[call_idx]}"
    return match.group(0)

content = re.sub(r'call (\d+)', replace_call, content)

# Write back
with open(sys.argv[2], 'w') as f:
    f.write(content)
PYTHON_SCRIPT

# Create mapping file
for old_idx in "${!OLD_TO_NEW[@]}"; do
    echo "$old_idx ${OLD_TO_NEW[$old_idx]}"
done > "$TEMP_DIR/mapping.txt"

echo "Mapping created:"
sort -n "$TEMP_DIR/mapping.txt"

# Build output file
cat "$TEMP_DIR/header.wat" > "$OUTPUT_FILE"

# Append functions in the new order and update their call instructions
for new_position in "${!NEW_ORDER[@]}"; do
    old_abs_idx="${NEW_ORDER[$new_position]}"
    new_abs_idx=$((IMPORT_COUNT + new_position))
    FUNC_FILE="$TEMP_DIR/func_${old_abs_idx}.wat"
    
    if [ -f "$FUNC_FILE" ]; then
        # Update call instructions in this function
        python3 "$TEMP_DIR/update_calls.py" "$IMPORT_COUNT" "$FUNC_FILE" < "$TEMP_DIR/mapping.txt"
        
        # Update the function index in the comment
        sed -i "s/(func (;$old_abs_idx;)/(func (;$new_abs_idx;)/g" "$FUNC_FILE"
        
        cat "$FUNC_FILE" >> "$OUTPUT_FILE"
    else
        echo "Error: Function $old_abs_idx not found" >&2
        exit 1
    fi
done

# Append footer
cat "$TEMP_DIR/footer.wat" >> "$OUTPUT_FILE"

echo "Reordered WAT file created: $OUTPUT_FILE"