# vim: shiftwidth=0 tabstop=4 expandtab
system: pkgs:
let

BASH   = "${pkgs.bash}/bin/bash";
CHMOD  = "${pkgs.coreutils}/bin/chmod";
CP     = "${pkgs.coreutils}/bin/cp";
GOPLS  = "${pkgs.gopls}/bin/gopls";
LN     = "${pkgs.coreutils}/bin/ln";
MKDIR  = "${pkgs.coreutils}/bin/mkdir";
NEOVIM = "${pkgs.neovim}/bin/nvim";

lspconfig-gopls =
    let rev = "030a72f0aa4d56f9e8ff67921e6e3ffd0e97bf07";
    in pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/neovim/nvim-lspconfig/${rev}/lsp/gopls.lua";
        hash = "sha256-Wyum8WuvpfBA2YeAlqzecMluitTWzSBb4XTS3k3P3wQ="; };

in
{
    default = derivation {
        inherit system;
        name = "neovim-go";
        builder = pkgs.writeShellScript "configure-neovim-go" ''
            ${MKDIR} -p $out/etc/lsp
            ${CP} ${lspconfig-gopls} $out/etc/lsp/gopls.lua
            ${MKDIR} -p $out/etc/lsp/gopls
            VERSION=$(${GOPLS} version)
            printf "\
            vim.print('Enabling Go Language Server: $VERSION')
            vim.lsp.enable('gopls')
            " > $out/etc/lsp/gopls/enable.lua
            printf "\
            anoremenu PopUp.-LSP- <NOP>
            anoremenu PopUp.Inspect      :lua vim.lsp.buf.hover()<CR>
            anoremenu PopUp.Code\ Action :lua vim.lsp.buf.code_action()<CR>
            anoremenu PopUp.References   :lua vim.lsp.buf.references()<CR>
            nnoremap gD :lua vim.lsp.buf.definition()<CR>
            nnoremap <C-Space> :lua vim.lsp.buf.code_action()<CR>
            " > $out/etc/lsp/gopls/enable.vim
            ${MKDIR} -p $out/bin
            printf "\
            #!${BASH}
            export PATH=\$PATH:${pkgs.go}/bin:${pkgs.gopls}/bin
            exec ${NEOVIM} \
                --cmd \"set runtimepath+=$out/etc\" \
                --cmd \"runtime! lsp/gopls/enable.lua lsp/gopls/enable.vim\" \
                \"\$@\"
            " > $out/bin/neovim-go
            ${CHMOD} +x $out/bin/neovim-go
            '';
    };
}
