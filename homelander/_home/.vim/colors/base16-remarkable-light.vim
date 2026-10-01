" reMarkable Light
" Warm paper-like Vim palette matching base16-remarkable.light.sh.

hi clear
if exists('syntax_on')
  syntax reset
endif
set background=light
let g:colors_name = 'base16-remarkable-light'

function! s:hi(group, guifg, guibg, ctermfg, ctermbg, attr)
  let l:cmd = 'hi ' . a:group
  if a:guifg !=# '' | let l:cmd .= ' guifg=#' . a:guifg | endif
  if a:guibg !=# '' | let l:cmd .= ' guibg=#' . a:guibg | endif
  if a:ctermfg !=# '' | let l:cmd .= ' ctermfg=' . a:ctermfg | endif
  if a:ctermbg !=# '' | let l:cmd .= ' ctermbg=' . a:ctermbg | endif
  if a:attr !=# '' | let l:cmd .= ' gui=' . a:attr . ' cterm=' . a:attr | endif
  execute l:cmd
endfunction

" Editor UI. NONE backgrounds preserve the terminal's paper color.
call s:hi('Normal',       '292a28', '',       '15', '',   'none')
call s:hi('Cursor',       'e3e1da', '292a28', '',   '',   'none')
call s:hi('CursorLine',   '',       'd8d6cf', '',   '18', 'none')
call s:hi('CursorColumn', '',       'd8d6cf', '',   '18', 'none')
call s:hi('ColorColumn',  '',       'd8d6cf', '',   '18', 'none')
call s:hi('LineNr',       '8a8b85', 'd8d6cf', '8',  '18', 'none')
call s:hi('CursorLineNr', '956600', 'd8d6cf', '3',  '18', 'bold')
call s:hi('SignColumn',   '8a8b85', 'd8d6cf', '8',  '18', 'none')
call s:hi('FoldColumn',   '007f86', 'd8d6cf', '6',  '18', 'none')
call s:hi('Folded',       '686964', 'd8d6cf', '7',  '18', 'none')
call s:hi('VertSplit',    'c5c4bd', 'c5c4bd', '19', '19', 'none')
call s:hi('StatusLine',   '292a28', 'c5c4bd', '15', '19', 'bold')
call s:hi('StatusLineNC', '686964', 'd8d6cf', '7',  '18', 'none')
call s:hi('TabLine',      '686964', 'd8d6cf', '7',  '18', 'none')
call s:hi('TabLineFill',  '686964', 'd8d6cf', '7',  '18', 'none')
call s:hi('TabLineSel',   '377748', 'c5c4bd', '2',  '19', 'bold')
call s:hi('Pmenu',        '292a28', 'd8d6cf', '15', '18', 'none')
call s:hi('PmenuSel',     'e3e1da', '326591', '0',  '4',  'bold')
call s:hi('Visual',       '',       'c5c4bd', '',   '19', 'none')
call s:hi('Search',       '292a28', 'b57d00', '15', '11', 'none')
call s:hi('IncSearch',    'e3e1da', '9c3d34', '0',  '1',  'bold')
call s:hi('MatchParen',   '292a28', 'b57d00', '15', '11', 'bold')
call s:hi('NonText',      '8a8b85', '',       '8',  '',   'none')
call s:hi('SpecialKey',   '8a8b85', '',       '8',  '',   'none')
call s:hi('Directory',    '326591', '',       '4',  '',   'bold')
call s:hi('Title',        '326591', '',       '4',  '',   'bold')
call s:hi('ErrorMsg',     '9c3d34', '',       '1',  '',   'bold')
call s:hi('WarningMsg',   '956600', '',       '3',  '',   'bold')
call s:hi('ModeMsg',      '377748', '',       '2',  '',   'bold')
call s:hi('MoreMsg',      '377748', '',       '2',  '',   'bold')
call s:hi('Question',     '326591', '',       '4',  '',   'bold')

" Syntax.
call s:hi('Comment',      '777873', '', '8',  '', 'italic')
call s:hi('Constant',     'aa6025', '', '16', '', 'none')
call s:hi('String',       '377748', '', '2',  '', 'none')
call s:hi('Character',    '9c3d34', '', '1',  '', 'none')
call s:hi('Number',       'aa6025', '', '16', '', 'none')
call s:hi('Boolean',      'aa6025', '', '16', '', 'bold')
call s:hi('Float',        'aa6025', '', '16', '', 'none')
call s:hi('Identifier',   '9c3d34', '', '1',  '', 'none')
call s:hi('Function',     '326591', '', '4',  '', 'none')
call s:hi('Statement',    '794982', '', '5',  '', 'bold')
call s:hi('Conditional',  '794982', '', '5',  '', 'bold')
call s:hi('Repeat',       '956600', '', '3',  '', 'bold')
call s:hi('Label',        '956600', '', '3',  '', 'none')
call s:hi('Operator',     '292a28', '', '15', '', 'none')
call s:hi('Keyword',      '794982', '', '5',  '', 'bold')
call s:hi('Exception',    '9c3d34', '', '1',  '', 'bold')
call s:hi('PreProc',      '956600', '', '3',  '', 'none')
call s:hi('Include',      '326591', '', '4',  '', 'none')
call s:hi('Define',       '794982', '', '5',  '', 'none')
call s:hi('Macro',        '9c3d34', '', '1',  '', 'none')
call s:hi('Type',         '956600', '', '3',  '', 'none')
call s:hi('StorageClass', '956600', '', '3',  '', 'none')
call s:hi('Structure',    '794982', '', '5',  '', 'none')
call s:hi('Typedef',      '956600', '', '3',  '', 'none')
call s:hi('Special',      '007f86', '', '6',  '', 'none')
call s:hi('SpecialChar',  '78473d', '', '17', '', 'none')
call s:hi('Tag',          '956600', '', '3',  '', 'none')
call s:hi('Delimiter',    '78473d', '', '17', '', 'none')
call s:hi('Underlined',   '326591', '', '4',  '', 'underline')
call s:hi('Todo',         '956600', 'd8d6cf', '3', '18', 'bold')
call s:hi('Error',        '9c3d34', 'd8d6cf', '1', '18', 'bold')

" Diff and spelling.
call s:hi('DiffAdd',      '377748', 'd8d6cf', '2', '18', 'none')
call s:hi('DiffChange',   '956600', 'd8d6cf', '3', '18', 'none')
call s:hi('DiffDelete',   '9c3d34', 'd8d6cf', '1', '18', 'none')
call s:hi('DiffText',     '326591', 'c5c4bd', '4', '19', 'bold')
call s:hi('SpellBad',     '', '', '', '', 'undercurl')
call s:hi('SpellCap',     '', '', '', '', 'undercurl')
call s:hi('SpellLocal',   '', '', '', '', 'undercurl')
call s:hi('SpellRare',    '', '', '', '', 'undercurl')

" Common plugin groups.
hi link GitGutterAdd DiffAdd
hi link GitGutterChange DiffChange
hi link GitGutterDelete DiffDelete
hi link SignifySignAdd DiffAdd
hi link SignifySignChange DiffChange
hi link SignifySignDelete DiffDelete
hi link NERDTreeDir Directory
hi link NERDTreeDirSlash Directory
