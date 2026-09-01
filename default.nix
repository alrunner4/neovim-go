# vim: shiftwidth=0 tabstop=4 expandtab
{ system ? builtins.currentSystem
, pkgs ? import <nixpkgs> {} }:
let

BASH      = "${pkgs.bash}/bin/bash";
CHMOD     = "${pkgs.coreutils}/bin/chmod";
CP        = "${pkgs.coreutils}/bin/cp";
GOPLS     = "${pkgs.gopls}/bin/gopls";
LN        = "${pkgs.coreutils}/bin/ln";
MKDIR     = "${pkgs.coreutils}/bin/mkdir";
NEOVIM    = "${pkgs.neovim}/bin/nvim";
NVIM_LINT = "${pkgs.vimPlugins.nvim-lint}";

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
        vim.print('Enabling Go Language Server: $VERSION')
        vim.lsp.enable('gopls')
        "

        printf >$out/etc/lsp/gopls/lint.lua "\
        local lint = require('lint')
        lint.linters_by_ft = {
            go = { 'golangcilint' }
        }
        function try_lint()
            local bufpath = vim.api.nvim_buf_get_name(0)
            local modfile = vim.fs.find('go.mod', { path = bufpath, upward = true })[1]
            local cwd = modfile and vim.fs.dirname(modfile) or nil
            lint.try_lint(nil, { cwd = cwd })
        end
        vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWritePost' }, { callback = try_lint })
        vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, {
            callback = function()
                if vim.bo.modified then
                    vim.cmd('silent! update')
                    try_lint()
                end
            end
        })
        "

        printf >$out/etc/lsp/gopls/enable.vim "\
        anoremenu PopUp.-LSP- <NOP>
        anoremenu PopUp.Inspect      :lua vim.lsp.buf.hover()<CR>
        anoremenu PopUp.Code\ Action :lua vim.lsp.buf.code_action()<CR>
        anoremenu PopUp.References   :lua vim.lsp.buf.references()<CR>
        nnoremap gD :lua vim.lsp.buf.definition({reuse_win = true})<CR>
        nnoremap <C-Space> :lua vim.lsp.buf.code_action()<CR>
        "

        ${MKDIR} -p $out/bin
        printf >$out/bin/neovim-go "\
        #!${BASH}
        export PATH=\$PATH:${pkgs.go}/bin:${pkgs.gopls}/bin:${pkgs.golangci-lint}/bin
        exec ${NEOVIM} \
            --cmd \"set runtimepath+=$out/etc,${NVIM_LINT}\" \
            --cmd \"runtime! lsp/gopls/enable.lua lsp/gopls/lint.lua lsp/gopls/enable.vim\" \
            \"\$@\"
        "
        ${CHMOD} +x $out/bin/neovim-go
        '';
}
