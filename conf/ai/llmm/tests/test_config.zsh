source "$LLMM_LIB/ui.zsh"

# ui::pick_index maps a 1-based choice string to a 0-based index, or -1 if invalid.
assert_eq "$(ui::pick_index 3 5)" 2 "ui::pick_index valid"
assert_eq "$(ui::pick_index 0 5)" -1 "ui::pick_index too-low"
assert_eq "$(ui::pick_index 6 5)" -1 "ui::pick_index too-high"
assert_eq "$(ui::pick_index abc 5)" -1 "ui::pick_index non-numeric"
assert_eq "$(ui::pick_index '' 5)" -1 "ui::pick_index empty"
