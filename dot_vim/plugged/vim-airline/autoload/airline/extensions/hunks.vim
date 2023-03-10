" MIT License. Copyright (c) 2013-2021 Bailey Ling et al.
" Plugin: vim-gitgutter, vim-signify, changesPlugin, quickfixsigns, coc-git,
"         gitsigns.nvim
" vim: et ts=2 sts=2 sw=2

scriptencoding utf-8

if !get(g:, 'loaded_signify', 0)
  \ && !get(g:, 'loaded_gitgutter', 0)
  \ && !get(g:, 'loaded_changes', 0)
  \ && !get(g:, 'loaded_quickfixsigns', 0)
  \ && !exists(':Gitsigns')
  \ && !exists("*CocAction")
  finish
endif

let s:non_zero_only = get(g:, 'airline#extensions#hunks#non_zero_only', 0)
let s:hunk_symbols = get(g:, 'airline#extensions#hunks#hunk_symbols', ['+', '~', '-'])

function! s:coc_git_enabled() abort
  if !exists("*CocAction") ||
   \ !get(g:, 'airline#extensions#hunks#coc_git', 0)
     " coc-git extension is disabled by default
     " unless specifically being enabled by the user
     " (as requested from coc maintainer)
    return 0
  endif
  return 1
endfunction

function! s:parse_hunk_status_dict(hunks) abort
  let result = [0, 0, 0]
  let result[0] = get(a:hunks, 'added', 0)
  let result[1] = get(a:hunks, 'changed', 0)
  let result[2] = get(a:hunks, 'removed', 0)
  return result
endfunction

function! s:parse_hunk_status_decorated(hunks) abort
  if empty(a:hunks)
    return []
  endif
  let result = [0, 0, 0]
  for val in split(a:hunks)
    if val[0] is# '+'
      let result[0] = val[1:] + 0
    elseif val[0] is# '~'
      let result[1] = val[1:] + 0
    elseif val[0] is# '-'
      let result[2] = val[1:] + 0
    endif
  endfor
  return result
endfunction

function! s:get_hunks_signify() abort
  let hunks = sy#repo#get_stats()
  if hunks[0] >= 0
    return hunks
  endif
  return []
endfunction

function! s:get_hunks_gitgutter() abort
  let hunks = GitGutterGetHunkSummary()
  return hunks == [0, 0, 0] ? [] : hunks
endfunction

function! s:get_hunks_changes() abort
  let hunks = changes#GetStats()
  return hunks == [0, 0, 0] ? [] : hunks
endfunction

function! s:get_hunks_gitsigns() abort
  let hunks = get(b:, 'gitsigns_status_dict', {})
  return s:parse_hunk_status_dict(hunks)
endfunction

function! s:get_hunks_coc() abort
  let hunks = get(b:, 'coc_git_status', '')
  return s:parse_hunk_status_decorated(hunks)
endfunction

function! s:get_hunks_empty() abort
  return ''
endfunction

function! airline#extensions#hunks#get_raw_hunks() abort
  if !exists('b:source_func') || get(b:, 'source_func', '') is# 's:get_hunks_empty'
    if get(g:, 'loaded_signify') && sy#buffer_is_active()
      let b:source_func = 's:get_hunks_signify'
    elseif exists('*GitGutterGetHunkSummary') && get(g:, 'gitgutter_enabled')
      let b:source_func = 's:get_hunks_gitgutter'
    elseif exists('*changes#GetStats')
      let b:source_func = 's:get_hunks_changes'
    elseif exists('*quickfixsigns#vcsdiff#GetHunkSummary')
      let b:source_func = 'quickfixsigns#vcsdiff#GetHunkSummary'
    elseif exists(':Gitsigns')
      let b:source_func = 's:get_hunks_gitsigns'
    elseif s:coc_git_enabled()
      let b:source_func = 's:get_hunks_coc'
    else
      let b:source_func = 's:get_hunks_empty'
    endif
  endif
  return {b:source_func}()
endfunction

function! airline#extensions#hunks#get_hunks() abort
  if !get(w:, 'airline_active', 0)
    return ''
  endif
  " Cache values, so that it isn't called too often
  if exists("b:airline_hunks") &&
    \ get(b:,  'airline_changenr', 0) == b:changedtick &&
    \ airline#util#winwidth() == get(s:, 'airline_winwidth', 0) &&
    \ get(b:, 'source_func', '') isnot# 's:get_hunks_signify' &&
    \ get(b:, 'source_func', '') isnot# 's:get_hunks_gitgutter' &&
    \ get(b:, 'source_func', '') isnot# 's:get_hunks_empty' &&
    \ get(b:, 'source_func', '') isnot# 's:get_hunks_changes' &&
    \ get(b:, 'source_func', '') isnot# 's:get_hunks_gitsigns' &&
    \ get(b:, 'source_func', '') isnot# 's:get_hunks_coc'
    return b:airline_hunks
  endif
  let hunks = airline#extensions#hunks#get_raw_hunks()
  let string = ''
  let winwidth = get(airline#parts#get('hunks'), 'minwidth', 100)
  if !empty(hunks)
    " hunks should contain [added, changed, deleted]
    for i in [0, 1, 2]
      if (s:non_zero_only == 0 && airline#util#winwidth() > winwidth) || hunks[i] > 0
        let string .= printf('%s%s ', s:hunk_symbols[i], hunks[i])
      endif
    endfor
  endif
  if index(airline#extensions#get_loaded_extensions(), 'branch') == -1 && string[-1:] == ' '
    " branch extension not loaded, skip trailing whitespace
    let string = string[0:-2]
  endif

  let b:airline_hunks = string
  let b:airline_changenr = b:changedtick
  let s:airline_winwidth = airline#util#winwidth()
  return string
endfunction

function! airline#extensions#hunks#init(ext) abort
  call airline#parts#define_function('hunks', 'airline#extensions#hunks#get_hunks')
endfunction
