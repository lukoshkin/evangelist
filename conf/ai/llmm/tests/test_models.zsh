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

# alias_for: canonical short alias, identical whether the model is named as an
# HF repo spec or as the downloaded .gguf file (so default + pick agree).
assert_eq "$(models::alias_for 'unsloth/Qwen3-Coder-Next-GGUF:UD-Q3_K_M')" "Qwen3-Coder-Next-UD-Q3_K_M" "alias from repo:quant"
assert_eq "$(models::alias_for '/m/x/Qwen3-Coder-Next-UD-Q3_K_M.gguf')" "Qwen3-Coder-Next-UD-Q3_K_M" "alias from file"
assert_eq "$(models::alias_for 'org/Some-Model-GGUF:Q4_K_M')" "Some-Model-Q4_K_M" "alias generic repo"
assert_eq "$(models::alias_for 'org/plain-repo')" "plain-repo" "alias repo no quant"
