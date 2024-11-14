{ config, pkgs, lib, ... }:

{
  home = {
    stateVersion = "24.05";
    username = "mrobertson";
    homeDirectory = "/home/mrobertson";
    
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less -R";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      PATH = "$HOME/bin:$PATH:$HOME/go/bin:$HOME/.local/bin:$HOME/.nix-profile/bin:$HOME/.cargo/env:$PATH";
    };

    packages = with pkgs; [
      visidata 
      duckdb 
      lazygit 
      cmake 
      pandoc 
      ripgrep-all 
      poppler_utils 
      tailscale 
      go 
      flock 
      python3 
      antiword 
      cargo 
      coreutils-full 
      fontconfig 
      pipx 
      lnav 
      restic 
      autorestic 
      restic-integrity 
      nmap 
      wget 
      tree
      imagemagick 
      yubikey-manager 
      gh 
      unison 
      zellij 
      unrar 
      git 
      delta 
      ripgrep 
      mcfly 
      bat 
      aha 
      ack 
      lua 
      moreutils 
      zoxide 
      broot 
      htop 
      ncdu 
      bupstash 
      xsv 
      ocrmypdf 
      eza 
      entr 
      exiftool 
      fd 
      yazi 
      pigz 
      pipx 
      docker 
      curl 
      fzf 
      zsh-fzf-tab 
      ffmpeg 
      pv 
      gron 
      jq 
      html2text 
      backblaze-b2 
      yt-dlp 
      zsh-autosuggestions 
      zsh-history-substring-search 
      zsh-syntax-highlighting 
      w3m 
      rsync 
      spaceship-prompt
    ];

    file = {
      ".config" = {
        source = /home/mrobertson/dotfiles/config;
        recursive = true;
      };
    };
  };
  
  # Enable systemd user service management
  systemd.user.startServices = "sd-switch";

  # Enable XDG base directories
  xdg = {
    enable = true;
    userDirs.enable = true;
  };

  programs.home-manager.enable = true;

  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = ["--cmd" "z"];
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--info=inline"
      ];
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
      fileWidgetOptions = [
        "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
      ];
      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
      changeDirWidgetOptions = ["--preview 'tree -C {} | head -200'"];
      historyWidgetOptions = ["--sort" "--exact"];
    };

    zsh = {
      enable = true;
      
      enableCompletion = true;
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;
      
      initExtraFirst = ''
        # Early initialization
        export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
        export PATH="$HOME/.nix-profile/bin:$PATH"

        # Initialize completion system early
        autoload -U compinit && compinit
        zmodload zsh/complist
      '';

      initExtra = ''
        # Bindkey stuff
        bindkey -e 
        bindkey '^ ' autosuggest-execute
        bindkey '^[^[[B' autosuggest-fetch
        bindkey '^X^E' edit-command-line
        
        # Completion settings
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
        zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
        zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

        # FZF Tab configuration
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:*' switch-group ',' '.'
        
        # Initialize mcfly
        if command -v mcfly >/dev/null 2>&1; then
          eval "$(mcfly init zsh)"
        fi

        # Source fzf-tab plugin
        if [ -f ~/.nix-profile/share/fzf-tab/fzf-tab.plugin.zsh ]; then
          source ~/.nix-profile/share/fzf-tab/fzf-tab.plugin.zsh
        fi

        function take() {
          mkdir -p "$1" && cd "$1"
        }

        function ya() {
          if [ "''${YAZILVL:-0}" -ne 0 ]; then
              echo "yazi is already running"
              return
          fi
          export YAZILVL=$((YAZILVL+1))
          local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              cd -- "$cwd"
          fi
          rm -f -- "$tmp"
          export YAZILVL=0
        }

        function rga-fzf () {
            local query="$1"      
            local extension="$2"  

            local RG_PREFIX="rga --files-with-matches --no-ignore --smart-case"
            
            if [ ! -z "$extension" ]; then
                RG_PREFIX="$RG_PREFIX -g '*.$extension'"
            fi

            local rg_pattern=$(echo "$query" | sed 's/[[:space:]]\+/.*\\&/g')

            echo "RG Command: $RG_PREFIX '$rg_pattern'"
            echo "Search Query: $query"

            FZF_DEFAULT_COMMAND="$RG_PREFIX '$rg_pattern'" \
                fzf --sort \
                    --preview="[[ ! -z {} ]] && rga --colors 'match:bg:yellow' --pretty --context 10 '$rg_pattern' {} | less -R" \
                    --multi \
                    --phony -q "$query" \
                    --color "hl:-1:underline,hl+:-1:underline:reverse" \
                    --bind "change:reload:$RG_PREFIX {q}" \
                    --preview-window="50%:wrap" \
                    --bind "enter:execute-silent(xdg-open {})"
        }

        function knit { Rscript -e "rmarkdown::render('$1')"; }

        # Zsh-Syntax-Highlighting
        autoload -U edit-command-line
        zle -N edit-command-line

        delete-small-word() {
          local WORDCHARS=$'!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'
          zle backward-kill-word
        }
        zle -N delete-small-word
        bindkey '^[^?' delete-small-word
        bindkey '^[^?' backward-kill-word
        bindkey '^[h' backward-kill-word

        # Compinit
        autoload -Uz compinit
        for dump in ~/.zcompdump(N.mh+24); do
          compinit
        done
        compinit -C
        autoload -U bashcompinit
        bashcompinit
      '';

      shellAliases = {
        sqlite = "sqlite3";
        b2 = "backblaze-b2";
        r = "radian";
        rg = "rg -i";
        pip = "uv pip";
        zl = "zellij";
        s5cmd-b2 = "s5cmd --endpoint-url https://s3.us-west-004.backblazeb2.com --credentials-file ~/bin/dotfiles/b2_credentials";
        ls = "eza";
        ll = "eza -alh";
        tree = "eza --tree";
        cat = "bat --plain --pager 'less -RF'";
        f = "xdg-open .";
        s = "source ./.venv/bin/activate";
        n = "ya";
      };

      plugins = [
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
        }
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
        }
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
        }
        {
          name = "spaceship-prompt";
          src = pkgs.spaceship-prompt;
        }
      ];

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" "docker" "kubectl" "fzf" ];
      };
    };

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        format = lib.concatStrings [
          "$line_break"
          "$time"
          "$git_branch"
          "$git_commit"
          "$git_status"
          "$exec_time"
          "$jobs"
          "$exit_code"
          "$python"
          "$directory"
          "$line_break"
          "$character"
        ];

        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };

        time = {
          disabled = false;
          format = "[$time]($style) ";
          style = "bold yellow";
        };

        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
          vimcmd_symbol = "[❮](bold blue)";
        };

        git_branch = {
          disabled = false;
          format = "[$branch]($style) ";
          style = "bold purple";
        };

        git_commit = {
          disabled = false;
          format = "[$hash]($style) ";
          style = "bold purple";
        };
        
        line_break = {
          disabled = false;
        };
      };
    };

neovim = {
    enable = true;
    extraPackages = with pkgs; [
      lua-language-server
      stylua
      ripgrep
    ];
    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];
    extraLuaConfig =
      let
        plugins = with pkgs.vimPlugins; [
          LazyVim
          bufferline-nvim
          cmp-buffer
          cmp-nvim-lsp
          cmp-path
          cmp_luasnip
          conform-nvim
          dashboard-nvim
          dressing-nvim
          flash-nvim
          friendly-snippets
          gitsigns-nvim
          indent-blankline-nvim
          lualine-nvim
          neo-tree-nvim
          neoconf-nvim
          neodev-nvim
          noice-nvim
          nui-nvim
          nvim-cmp
          nvim-lint
          nvim-lspconfig
          nvim-notify
          nvim-spectre
          nvim-treesitter
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-ts-autotag
          nvim-ts-context-commentstring
          nvim-web-devicons
          persistence-nvim
          plenary-nvim
          telescope-fzf-native-nvim
          telescope-nvim
          todo-comments-nvim
          tokyonight-nvim
          trouble-nvim
          vim-illuminate
          vim-startuptime
          which-key-nvim
          { name = "LuaSnip"; path = luasnip; }
          { name = "catppuccin"; path = catppuccin-nvim; }
          { name = "mini.ai"; path = mini-nvim; }
          { name = "mini.bufremove"; path = mini-nvim; }
          { name = "mini.comment"; path = mini-nvim; }
          { name = "mini.indentscope"; path = mini-nvim; }
          { name = "mini.pairs"; path = mini-nvim; }
          { name = "mini.surround"; path = mini-nvim; }
        ];
        mkEntryFromDrv = drv:
          if lib.isDerivation drv then
            { name = "${lib.getName drv}"; path = drv; }
          else
            drv;
        lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in
      ''
        -- Set parser install location before lazy setup
        vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/treesitter")
        require('nvim-treesitter.configs').setup({
          parser_install_dir = vim.fn.stdpath("data") .. "/treesitter",
          ensure_installed = {},
          highlight = { enable = true },
          indent = { enable = true },
        })
        require("lazy").setup({
          defaults = {
            lazy = true,
          },
          dev = {
            path = "${lazyPath}",
            patterns = { "." },
            fallback = true,
          },
          spec = {
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            { "williamboman/mason.nvim", enabled = false },
            { import = "plugins" },
            { "nvim-treesitter/nvim-treesitter", opts = { 
                ensure_installed = {},
                parser_install_dir = vim.fn.stdpath("data") .. "/treesitter"
              }
            },
          },
        })
      '';
  };
 };
}
