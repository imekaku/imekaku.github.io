---
layout: post
title: 我的配置
category: other
---

# 配置清单

有些时候经常换设备，导致使用的软件配置总是不一样。所以觉得还是用老办法纪录在这里，可能会更方便寻找一些。

## opencode 配置文件

```
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "codegraph": {
      "command": [
        "codegraph",
        "serve",
        "--mcp"
      ],
      "enabled": true,
      "type": "local"
    }
  },
  "model": "kimi/kimi-k2.7-code",
  "permission": {
    "*": "allow"
  },
  "provider": {
    "deepseek": {
      "models": {
        "deepseek-v4-flash": {
          "id": "deepseek-v4-flash",
          "name": "DeepSeek V4 Flash"
        },
        "deepseek-v4-pro": {
          "id": "deepseek-v4-pro",
          "name": "DeepSeek V4 Pro"
        }
      },
      "name": "DeepSeek",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "apiKey": "{env:DEEPSEEK_API_KEY}",
        "baseURL": "https://api.deepseek.com"
      }
    },
    "glm": {
      "models": {
        "glm-5.3": {
          "name": "glm-5.3"
        }
      },
      "name": "GLM",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "apiKey": "{env:GLM_API_KEY}",
        "baseURL": "https://open.bigmodel.cn/api/paas/v4"
      }
    },
    "kimi": {
      "models": {
        "kimi-k2.5": {
          "id": "kimi-k2.5",
          "name": "kimi-k2.5"
        },
        "kimi-k2.7-code": {
          "id": "kimi-k2.7-code",
          "name": "kimi-k2.7-code"
        },
        "kimi-k3": {
          "id": "kimi-k3",
          "name": "kimi-k3"
        },
        "kimi-k3.1-pro": {
          "id": "kimi-k3.1-pro",
          "name": "kimi-k3.1-pro"
        }
      },
      "name": "Kimi",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "apiKey": "{env:KIMI_API_KEY}",
        "baseURL": "https://api.moonshot.cn/v1"
      }
    }
  }
}
```

opencode 命令行配置：
```
{
  "$schema": "https://opencode.ai/v2/cli.json",
  "theme": {
    "name": "orng"
  },
  "plugins": [
  ],
  "diffs": {
    "wrap": "word"
  },
  "keybinds": {
    "session.new": "super+shift+n,<leader>n",
    "session.tab.close": "super+shift+w,<leader>w",
    "session.tab.previous": "super+shift+left",
    "session.tab.next": "super+shift+right"
  },
  "session": {
    "sidebar": "auto",
    "scrollbar": false,
    "thinking": "hide"
  },
  "animations": true
}
```

对应的用户目录下 `.bashrc` 的内容：

```
lee@mac-mini-m4:~$ cat .bashrc

. "$HOME/.cargo/env"

# kimi-code
export PATH="/Users/lee/.kimi-code/bin:$PATH"

# opencode
export PATH=/Users/lee/.opencode/bin:$PATH

# opencode provider API keys
export GLM_API_KEY="xx"
export DEEPSEEK_API_KEY="sk-xx"
export KIMI_API_KEY="sk-xx"
```

## ghostty 配置

```
palette = 1=#FF4444
palette = 2=#44FF44
title = "Teminal"
theme = "Dark Pastel"
font-family = "Monaco"
confirm-close-surface = false
```

## 环境配置

```
# 配置使用pwd并且复制路径到粘贴板
pwd() {
    # 调用原始 pwd 命令获取路径（支持 -L/-P 等选项）
    local path
    path=$(command pwd "$@")

    # 输出路径（与原 pwd 行为一致）
    echo "$path"

    # 尝试将路径复制到剪贴板（支持多种环境）
    if command -v xclip &>/dev/null; then
        echo -n "$path" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        echo -n "$path" | xsel --clipboard --input
    elif command -v wl-copy &>/dev/null; then
        echo -n "$path" | wl-copy
    elif command -v pbcopy &>/dev/null; then
        echo -n "$path" | pbcopy
    fi
}

# 配置history历史
export HISTSIZE=100000
export HISTFILESIZE=1000000
export HISTFILE=~/.commandline_warrior
export HISTTIMEFORMAT="%Y-%M-%D %H:%M:%S  "
export PROMPT_COMMAND='history -a'
export HISTCONTROL=ignoredups:erasedups
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# 配置颜色
export LS_OPTIONS='--color=auto'
export CLICOLOR='Yes'
export LSCOLORS='gxfxcxdxbxegedabagGxGx'
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
printf '\033]12;red\007'

# 配置别名
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
alias ll='ls -alh -G'
alias ls='ls -G'
```