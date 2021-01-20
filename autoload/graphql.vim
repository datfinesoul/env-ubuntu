if polyglot#init#is_disabled(expand('<sfile>:p'), 'graphql', 'autoload/graphql.vim')
  finish
endif

" Copyright (c) 2016-2020 Jon Parise <jon@indelible.org>
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
" IN THE SOFTWARE.
"
" Language: GraphQL
" Maintainer: Jon Parise <jon@indelible.org>

function! graphql#has_syntax_group(group) abort
  try
    silent execute 'silent highlight ' . a:group
  catch
    return v:false
  endtry
  return v:true
endfunction

function! graphql#javascript_tags() abort
  return get(g:, 'graphql_javascript_tags', ['gql', 'graphql', 'Relay.QL'])
endfunction
