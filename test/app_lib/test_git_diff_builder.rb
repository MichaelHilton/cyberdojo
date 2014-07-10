  test 'chunk with a space in its filename' do
    @diff_lines =
    ]

    @source_lines =
    ]
    @expected =
    assert_equal_builder
  test 'chunk with defaulted now line info' do
    @diff_lines =
    ]

    @source_lines =
    ]
    @expected =
    assert_equal_builder
  test 'two chunks with leading and trailing same lines ' +
    @diff_lines =
      ' aaa',
      '-bbb',
      '+ccc',
      ' ddd',
      ' eee',
      ' fff',
      ' nnn',
      ' ooo',
      ' ppp',
      '-qqq',
      '+rrr',
      ' sss',
      ' ttt',
    ]
    @source_lines =
    [
      'aaa',
      'ccc',
      'ddd',
      'eee',
      'fff',
      'ggg',
      'hhh',
      'nnn',
      'ooo',
      'ppp',
      'rrr',
      'sss',
      'ttt'
    ]
    @expected =
      same_line('aaa', 1),
      deleted_line('bbb', 2),
      added_line('ccc', 2),
      same_line('ddd',  3),
      same_line('eee',  4),
      same_line('fff',  5),
      same_line('ggg',  6),
      same_line('hhh',  7),
      same_line('nnn',  8),
      same_line('ooo',  9),
      same_line('ppp', 10),
      deleted_line('qqq', 11),
      added_line('rrr', 11),
      same_line('sss', 12),
      same_line('ttt', 13)
    assert_equal_builder
  test 'diffs 7 lines apart are not merged ' +
       'into contiguous sections in one chunk' do
    @diff_lines =
      '-aaa',
      '+bbb',
      ' ccc',
      ' ddd',
      ' eee',
      ' ppp',
      ' qqq',
      ' rrr',
      '-sss',
      '+ttt'
    ]
    @source_lines =
    [
      'bbb',
      'ccc',
      'ddd',
      'eee',
      'fff',
      'ppp',
      'qqq',
      'rrr',
      'ttt'
    ]
    @expected =
      deleted_line('aaa', 1),
      added_line('bbb', 1),
      same_line('ccc', 2),
      same_line('ddd', 3),
      same_line('eee', 4),
      same_line('fff', 5),
      same_line('ppp', 6),
      same_line('qqq', 7),
      same_line('rrr', 8),
      deleted_line('sss', 9),
      added_line('ttt', 9)
    assert_equal_builder
  test 'one chunk with two sections ' +
    @diff_lines =
      ' aaa',
      ' bbb',
      '-ccc',
      '+ddd',
      ' eee',
      '-fff',
      '+ggg',
      ' hhh',
      ' iii',
      ' jjj'
    ]
    @source_lines =
    [
      'aaa',
      'bbb',
      'ddd',
      'eee',
      'ggg',
      'hhh',
      'iii',
      'jjj'
    ]
    @expected =
      same_line('aaa', 1),
      same_line('bbb', 2),
      deleted_line('ccc', 3),
      added_line('ddd', 3),
      same_line('eee', 4),
      deleted_line('fff', 5),
      added_line('ggg', 5),
      same_line('hhh', 6),
      same_line('iii', 7),
      same_line('jjj', 8)
    assert_equal_builder
  test 'one chunk with one section with only lines added' do
    @diff_lines =
      ' aaa',
      ' bbb',
      ' ccc',
      '+ddd',
      '+eee',
      '+fff',
      ' ggg',
      ' hhh',
      ' iii'
    ]
    @source_lines =
    [
      'aaa',
      'bbb',
      'ccc',
      'ddd',
      'eee',
      'fff',
      'ggg',
      'hhh',
      'iii',
      'jjj'
    ]
    @expected =
      same_line('aaa', 1),
      same_line('bbb', 2),
      same_line('ccc', 3),
      added_line('ddd', 4),
      added_line('eee', 5),
      added_line('fff', 6),
      same_line('ggg', 7),
      same_line('hhh', 8),
      same_line('iii', 9),
      same_line('jjj', 10)
    assert_equal_builder
  test 'one chunk with one section with only lines deleted' do
    @diff_lines =
    ]

    @source_lines =
    ]
    @expected =
    assert_equal_builder
  test 'one chunk with one section ' +
    @diff_lines =
      ' ddd',
      ' eee',
      ' fff',
      '-ggg',
      '-hhh',
      '-iii',
      '+jjj',
      ' kkk',
      ' lll',
      ' mmm'
    ]
    @source_lines =
    [
      'bbb',
      'ccc',
      'ddd',
      'eee',
      'fff',
      'jjj',
      'kkk',
      'lll',
      'mmm',
      'nnn'
    ]
    @expected =
      same_line('bbb', 1),
      same_line('ccc', 2),
      same_line('ddd', 3),
      same_line('eee', 4),
      same_line('fff', 5),
      deleted_line('ggg', 6),
      deleted_line('hhh', 7),
      deleted_line('iii', 8),
      added_line('jjj', 6),
      same_line('kkk', 7),
      same_line('lll', 8),
      same_line('mmm', 9),
      same_line('nnn', 10)
    assert_equal_builder
  test 'one chunk with one section ' +
    @diff_lines =
    ]

    @source_lines =
    ]
    @expected =
    assert_equal_builder
  test 'one chunk with one section ' +
    @diff_lines =
    ]

    @source_lines =
    @expected =
    assert_equal_builder
  def assert_equal_builder
    diff = GitDiff::GitDiffParser.new(@diff_lines.join("\n")).parse_one
    builder = GitDiff::GitDiffBuilder.new()
    actual = builder.build(diff, @source_lines)
    assert_equal @expected, actual