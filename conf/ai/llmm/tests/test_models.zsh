source "$LLMM_LIB/ui.zsh"
source "$LLMM_LIB/config.zsh"
source "$LLMM_LIB/models.zsh"

# Label: HF-cache path -> "[hf] org/repo  file.gguf"; split org--repo on FIRST '--'.
hf="/x/huggingface/hub/models--unsloth--Qwen3-Coder-Next-GGUF/snapshots/abc/model-Q3.gguf"
assert_contains "$(models::label "$hf")" "[hf]" "label hf tag"
assert_contains "$(models::label "$hf")" "unsloth/Qwen3-Coder-Next-GGUF" "label hf repo"
assert_contains "$(models::label "$hf")" "model-Q3.gguf" "label hf file"

# Repo name that itself contains '--' must only split on the first one.
hf2="/x/huggingface/hub/models--meta-llama--Meta-Llama-3--8B/snapshots/d/m.gguf"
assert_contains "$(models::label "$hf2")" "meta-llama/Meta-Llama-3--8B" "label hf double-dash"

# Local path -> "[local] file.gguf"
assert_contains "$(models::label /opt/models/foo.gguf)" "[local] foo.gguf" "label local"

# Discover finds the symlinked .gguf inside the fixture HF hub (find -L).
fx="$LLMM_TESTS_DIR/fixtures"
LLMM_DISCOVER_DIRS=("$fx/models" "$fx/hub")
out="$(models::discover)"
assert_contains "$out" "tiny-Q3_K_M.gguf" "discover local"
assert_contains "$out" "fixture-model.gguf" "discover hf symlink"
unset LLMM_DISCOVER_DIRS
