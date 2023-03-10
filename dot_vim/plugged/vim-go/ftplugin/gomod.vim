" gomod.vim: Vim filetype plugin for Go assembler.

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

let b:undo_ftplugin = "setl fo< com< cms<
      \ | exe 'au! vim-go-gomod-buffer * <buffer>'"

setlocal formatoptions-=t

setlocal comments=://
setlocal commentstring=//\ %s

" Autocommands
" ============================================================================

augroup vim-go-gomod-buffer
  autocmd! * <buffer>

  autocmd BufWritePre <buffer> call go#auto#modfmt_autosave()
  if go#util#has_job()
    autocmd BufWritePost,FileChangedShellPost <buffer> call go#lsp#ModReload(resolve(expand('<afile>:p')))
  endif
augroup end

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et
