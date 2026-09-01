# vim: shiftwidth=0 tabstop=4 expandtab
{ system ? builtins.currentSystem
, pkgs ? import <nixpkgs> {} }:
let

BASH   = "${pkgs.bash}/bin/bash";
CHMOD  = "${pkgs.coreutils}/bin/chmod";
CP     = "${pkgs.coreutils}/bin/cp";
GOPLS  = "${pkgs.gopls}/bin/gopls";
LINT   = "${pkgs.golangci-lint}/bin/golangci-lint";
LN     = "${pkgs.coreutils}/bin/ln";
MKDIR  = "${pkgs.coreutils}/bin/mkdir";
NEOVIM = "${pkgs.neovim}/bin/nvim";

lspconfig-gopls =
    let rev = "030a72f0aa4d56f9e8ff67921e6e3ffd0e97bf07";
    in pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/neovim/nvim-lspconfig/${rev}/lsp/gopls.lua";
        hash = "sha256-Wyum8WuvpfBA2YeAlqzecMluitTWzSBb4XTS3k3P3wQ="; };

in derivation {
    inherit system;
    name = "neovim-go";
    builder = pkgs.writeShellScript "configure-neovim-go" ''
        ${MKDIR} -p $out/etc/lsp
        ${CP} ${lspconfig-gopls} $out/etc/lsp/gopls.lua

        ${MKDIR} -p $out/etc/lsp/gopls
        VERSION=$(${GOPLS} version)
        printf >$out/etc/lsp/gopls/enable.lua "\
        vim.print('Enabling Go Language Server: $(${GOPLS} version), $(${LINT} version)')
        vim.lsp.config('golangci_lint', {
            cmd = { 'golangci-lint-langserver' },
            filetypes = { 'go', 'gomod' },
            root_markers = { '.golangci.yaml' },
            init_options = {
                command = {
                    'golangci-lint',
                    'run',
                    '--output.json.path=stdout',
                    '--show-stats=false',
                }
            },
            handlers = {
                ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
                    if result and result.uri then
                        vim.print("golangci-lint URI: " .. result.uri)
                    end
                    vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
                end
            }
        })
        vim.lsp.enable('gopls')
        vim.lsp.enable('golangci_lint')
        "

        printf "\
        anoremenu PopUp.-LSP- <NOP>
        anoremenu PopUp.Inspect      :lua vim.lsp.buf.hover()<CR>
        anoremenu PopUp.Code\ Action :lua vim.lsp.buf.code_action()<CR>
        anoremenu PopUp.References   :lua vim.lsp.buf.references()<CR>
        nnoremap gD :lua vim.lsp.buf.definition({reuse_win = true})<CR>
        nnoremap <C-Space> :lua vim.lsp.buf.code_action()<CR>
        " > $out/etc/lsp/gopls/enable.vim

        ${MKDIR} -p $out/bin
        printf "\
        #!${BASH}
        export PATH=\$PATH:${pkgs.go}/bin:${pkgs.gopls}/bin:${pkgs.golangci-lint}/bin:${pkgs.golangci-lint-langserver}/bin
        exec ${NEOVIM} \
            --cmd \"set runtimepath+=$out/etc\" \
            --cmd \"runtime! lsp/gopls/enable.lua lsp/gopls/enable.vim\" \
            \"\$@\"
        " > $out/bin/neovim-go
        ${CHMOD} +x $out/bin/neovim-go
        '';
}
