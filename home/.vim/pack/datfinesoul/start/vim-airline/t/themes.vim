describe 'themes'
  after
    highlight clear Foo
    highlight clear Normal
  end

  it 'should extract correct colors'
    call airline#highlighter#reset_hlcache()
    highlight Foo ctermfg=1 ctermbg=2
    let colors = airline#themes#get_highlight('Foo')
    Expect colors[2] == '1'
    Expect colors[3] == '2'
  end

  it 'should extract from normal if colors unavailable'
    call airline#highlighter#reset_hlcache()
    highlight Normal ctermfg=100 ctermbg=200
    highlight Foo ctermbg=2
    let colors = airline#themes#get_highlight('Foo')
    Expect colors[2] == '100'
    Expect colors[3] == '2'
  end

  it 'should flip target group if it is reversed'
    call airline#highlighter#reset_hlcache()
    highlight Foo ctermbg=222 ctermfg=103 term=reverse
    let colors = airline#themes#get_highlight('Foo')
    Expect colors[2] == '222'
    Expect colors[3] == '103'
  end

  it 'should pass args through correctly'
    call airline#highlighter#reset_hlcache()
    hi clear Normal
    let hl = airline#themes#get_highlight('Foo', 'bold', 'italic')
    Expect hl == ['', '', 'NONE', 'NONE', 'bold,italic']

    let hl = airline#themes#get_highlight2(['Foo','bg'], ['Foo','fg'], 'italic', 'bold')
    Expect hl == ['', '', 'NONE', 'NONE', 'italic,bold']
  end

  it 'should generate color map with mirroring'
    let map = airline#themes#generate_color_map(
          \ [ 1, 1, 1, 1, '1' ],
          \ [ 2, 2, 2, 2, '2' ],
          \ [ 3, 3, 3, 3, '3' ],
          \ )
    Expect map.airline_a[0] == 1
    Expect map.airline_b[0] == 2
    Expect map.airline_c[0] == 3
    Expect map.airline_x[0] == 3
    Expect map.airline_y[0] == 2
    Expect map.airline_z[0] == 1
  end

  it 'should generate color map with full set of colors'
    let map = airline#themes#generate_color_map(
          \ [ 1, 1, 1, 1, '1' ],
          \ [ 2, 2, 2, 2, '2' ],
          \ [ 3, 3, 3, 3, '3' ],
          \ [ 4, 4, 4, 4, '4' ],
          \ [ 5, 5, 5, 5, '5' ],
          \ [ 6, 6, 6, 6, '6' ],
          \ )
    Expect map.airline_a[0] == 1
    Expect map.airline_b[0] == 2
    Expect map.airline_c[0] == 3
    Expect map.airline_x[0] == 4
    Expect map.airline_y[0] == 5
    Expect map.airline_z[0] == 6
  end
end
