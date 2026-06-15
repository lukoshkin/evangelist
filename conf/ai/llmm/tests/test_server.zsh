source "$LLMM_LIB/ui.zsh"
source "$LLMM_LIB/config.zsh"
source "$LLMM_LIB/server.zsh"

typeset -gA LLMM_PROFILES=(
  default.ctx_size 65536 default.gpu_layers auto default.flash_attn on default.warmup 1 default.mmap 0
  minimal.ctx_size 16384 minimal.gpu_layers auto minimal.flash_attn on minimal.warmup 0 minimal.mmap 0
)

# Local model arg uses --model only when the path is a real file (build_args tests -f).
lm="$(mktemp -d)/m.gguf"; : > "$lm"

# Arg builder: default profile keeps warmup (warmup=1 -> no --no-warmup).
args="$(server::build_args default "$lm" myalias 11111)"
assert_contains "$args" "--ctx-size 65536" "args ctx"
assert_contains "$args" "--alias myalias" "args alias"
assert_contains "$args" "--model $lm" "args local model"
[[ "$args" != *"--no-warmup"* ]] && pass1=ok || pass1=no
assert_eq "$pass1" ok "default keeps warmup"

# minimal profile adds --no-warmup and --no-mmap.
amin="$(server::build_args minimal "$lm" a 11111)"
assert_contains "$amin" "--no-warmup" "minimal no-warmup"
assert_contains "$amin" "--no-mmap" "minimal no-mmap"
assert_contains "$amin" "--ctx-size 16384" "minimal ctx"

# Remote repo (not an existing file) uses --hf-repo.
arepo="$(server::build_args default org/repo:Q3 a 11111)"
assert_contains "$arepo" "--hf-repo org/repo:Q3" "args hf-repo"

# Meta round-trip.
tmp="$(mktemp -d)"; XDG_STATE_HOME="$tmp"
server::meta_write 11111 4242 "$lm" myalias 65536 default
assert_eq "$(server::meta_get 11111 pid)" 4242 "meta pid"
assert_eq "$(server::meta_get 11111 alias)" myalias "meta alias"
assert_eq "$(server::meta_get 11111 profile)" default "meta profile"

# Rotation decision: rotate only when size (MiB) exceeds cap.
assert_eq "$(server::should_rotate 60 50)" yes "rotate over cap"
assert_eq "$(server::should_rotate 10 50)" no  "no rotate under cap"
rm -rf "$tmp"
unset XDG_STATE_HOME
