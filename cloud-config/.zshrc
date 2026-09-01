# ============================================================
#  Ava's zsh — lightweight, starship, no oh-my-zsh bloat
#  Rebuilt from ~/.bashrc + ~/.zshrc.old (old termux setup)
# ============================================================

# ---------- PATH & env (merged) ----------
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# uv
export UV_PYTHON_PREFERENCE=only-system
export UV_LINK_MODE=copy

# AI mentor (CodeCompanion) — GROQ API Key
if [ -f "$HOME/.config/groq.env" ] && [ -z "$GROQ_API_KEY" ]; then
  export GROQ_API_KEY="$(grep -E '^GROQ_API_KEY=' "$HOME/.config/groq.env" | head -1 | cut -d= -f2-)"
fi

# ---------- Aliases ----------
alias ls='eza --group-directories-first'
alias ll='eza -la --group-directories-first'
alias l='eza -la --group-directories-first'
alias tree='eza --tree --level=2'
alias cat='bat'
alias v='nvim'
alias zshrc='nvim ~/.zshrc'

# ---------- zsh core ----------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_all_dups hist_reduce_blanks share_history
setopt auto_cd extendedglob no_beep
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ---------- plugins (guarded multi-distro) ----------
for p in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
         /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [ -f "$p" ] && { source "$p"; break; }
done

for p in /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
         /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -f "$p" ] && { source "$p"; break; }
done

# ---------- fzf (guarded multi-distro) ----------
for p in /usr/share/doc/fzf/examples/completion.zsh /usr/share/fzf/completion.zsh; do
  [ -f "$p" ] && { source "$p"; break; }
done
for p in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
  [ -f "$p" ] && { source "$p"; break; }
done

# ---------- starship prompt ----------
eval "$(starship init zsh)"
