" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! go#fillstruct#FillStruct() abort
  let l:mode = go#config#FillStructMode()
  if l:mode is 'gopls'
    if !go#config#GoplsEnabled()
      call go#util#EchoError("go_fillstruct_mode is 'gopls', but gopls is disabled")
      return
    endif

    call go#lsp#FillStruct()
    return
  endif

  let l:cmd = ['fillstruct',
      \ '-file', bufname(''),
      \ '-offset', go#util#OffsetCursor(),
      \ '-line', line('.')]
      " Needs: https://github.com/davidrjenni/reftools/pull/14
      "\ '-tags', go#config#BuildTags()]

  let l:buildtags = go#config#BuildTags()
  if l:buildtags isnot ''
    let l:cmd += ['-tags', l:buildtags]
  endif

  " Read from stdin if modified.
  if &modified
    call add(l:cmd, '-modified')
    let [l:out, l:err] = go#util#Exec(l:cmd, go#util#archive())
  else
    let [l:out, l:err] = go#util#Exec(l:cmd)
  endif

  if l:err
    call go#util#EchoError(l:out)
    return
  endif

  try
    let l:json = json_decode(l:out)
  catch
    call go#util#EchoError(l:out)
    return
  endtry

  " Output is array:
  "[
  "   {"start": 92, "end": 106, "code": "mail.Address{\n\tName:    \"\",\n\tAddress: \"\",\n}"},
  "   {...second struct...}
  " ]

  let l:pos = getpos('.')

  try
    for l:struct in l:json
      let l:code = split(l:struct['code'], "\n")

      " Add any code before/after the struct.
      exe l:struct['start'] . 'go'
      let l:code[0] = getline('.')[:col('.')-1] . l:code[0]
      exe l:struct['end'] . 'go'
      let l:code[len(l:code)-1] .= getline('.')[col('.'):]

      " Indent every line except the first one; makes it look nice.
      let l:indent = repeat("\t", indent('.') / &tabstop)
      for l:i in range(1, len(l:code)-1)
        let l:code[l:i] = l:indent . l:code[l:i]
      endfor

      " Out with the old ...
      exe 'normal! ' . l:struct['start'] . 'gov' . l:struct['end'] . 'gox'
      " ... in with the new.
      call setline('.', l:code[0])
      call append('.', l:code[1:])
    endfor
  finally
    call setpos('.', l:pos)
  endtry
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et
