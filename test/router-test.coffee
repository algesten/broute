
router = require '../src/router'

describe 'router', ->

    path = navigate = win = null
    beforeEach ->
        win = {}
        {path, navigate} = router(win)

    it 'blows up if not object', ->
        assert.throws router, 'router must be created around an object'

    it 'adds an event listener if addEventListener is there', ->
        win = {addEventListener: spy ->}
        {path, navigate} = router(win)
        assert win.addEventListener.calledWith 'popstate', match.func

    it 'runs the path function on popstate', ->
        win = {addEventListener: spy ->}
        {path} = router(win)
        path s = spy ->
        win.location = pathname:'/a'
        eql s.args, []
        win.addEventListener.args[0][1]() # invoke 'popstate' listener
        eql s.args, [['/a',{}]]

    describe 'navigate', ->

        TESTS = [
            ['/panda', '/panda', '']
            ['/panda?', '/panda', '?']
            ['/panda?q', '/panda', '?q']
            ['/panda?q=42', '/panda', '?q=42']
        ]

        TESTS.forEach (t) ->
            it "updates win.location for #{t[0]}", ->
                navigate t[0]
                eql win, location:{pathname:t[1], search:t[2]}

        it 'uses pushState if available', ->
            win = {history:pushState:spy ->}
            {navigate} = router(win)
            navigate '/yo'
            eql win.history.pushState.args, [[{}, null, '/yo']]

        it 'is lazy in path', ->
            path p = spy ->
                path 'a', ->
                    navigate 'b'
                    navigate 'c'
                path 'c', ->
                    navigate 'd'
                    navigate 'e'
            navigate 'a'
            eql p.args, [['a',{}],['c',{}],['e',{}]]

        it 'doesnt fire if path is exactly the same', ->
            path s = spy ->
            eql s.args, []
            navigate('/blah?foo=bar')
            eql s.args, [['/blah', foo:'bar']]
            navigate('/blah?foo=bar') # do nothing
            eql s.args, [['/blah', foo:'bar']]

        it 'runs current location if invoked without arguments', ->
            {path, navigate} = router(location:{pathname:'/panda', search:'?bear=true'})
            path s = spy ->
            eql s.args, []
            navigate()
            eql s.args, [['/panda', bear:'true']]
            navigate() # should do nothing
            eql s.args, [['/panda', bear:'true']]

        it 'runs current location again if new root installed', ->
            {path, navigate} = router(location:{pathname:'/panda', search:'?bear=true'})
            path s1 = spy ->
            navigate()
            eql s1.args, [['/panda', bear:'true']]
            path s2 = spy ->
            navigate()
            eql s1.args, [['/panda', bear:'true']]
            eql s2.args, [['/panda', bear:'true']]

    describe 'path', ->

        level1 = level2a = level2b = null
        path1 = path1e = path2 = path2e = path2b = path2be = null
        beforeEach ->
            level1 = spy(); level2a = spy(); level2b = spy()
            path ->
                path '/level1', (path1 = spy ->
                    level1 true
                    path '/level2', (path2 = spy ->
                        level2a true
                    ), path2e = spy ->
                        level2a false
                    path '/level2b', (path2b = spy ->
                        level2b true
                    ), path2be = spy ->
                        level2b false
                ), path1e = spy ->
                    level1 false

        TESTS = [
            ['',        [[[false]], [], []], [[], [["",{}]],              0, 0, 0, 0]]
            ['?',       [[[false]], [], []], [[], [["",{}]],              0, 0, 0, 0]]
            ['?a',      [[[false]], [], []], [[], [["",{a:''}]],          0, 0, 0, 0]]
            ['?a=b',    [[[false]], [], []], [[], [["",{a:'b'}]],         0, 0, 0, 0]]
            ['/',       [[[false]], [], []], [[], [["/",{}]],             0, 0, 0, 0]]
            ['/panda',  [[[false]], [], []], [[], [["/panda",{}]],        0, 0, 0, 0]]
            ['/level',  [[[false]], [], []], [[], [["/level",{}]],        0, 0, 0, 0]]
            ['/level1', [[[true]], [[false]], [[false]]], [[["",{}]], [], [], [["",{}]], [], [["",{}]]]]
            ['/level1/ab', [[[true]], [[false]], [[false]]], [[["/ab",{}]], [], [], [["/ab",{}]], [], [["/ab",{}]]]]
            ['/level1/level2', [[[true]], [[true]], [[false]]], [[["/level2",{}]], [], [["",{}]], [], [], [["/level2",{}]]]]
            ['/level1/level2b', [[[true]], [[true]], [[true]]], [[["/level2b",{}]], [], [["b",{}]], [], [["",{}]], []]]
            ['/level1/level2ba', [[[true]], [[true]], [[true]]], [[["/level2ba",{}]], [], [["ba",{}]], [], [["a",{}]], []]]
            ['/level1/level2ba?a=b', [[[true]], [[true]], [[true]]], [[["/level2ba",{a:'b'}]], [], [["ba",{a:'b'}]], [], [["a",{a:'b'}]], []]]
        ]

        TESTS.forEach (t) -> it "works for #{t[0]}", ->
            navigate t[0]
            eql level1.args,  t[1][0]
            eql level2a.args, t[1][1]
            eql level2b.args, t[1][2]
            eql path1.args,   t[2][0]
            eql path1e.args,  t[2][1]
            eql path2.args,   t[2][2] if t[2][2]
            eql path2e.args,  t[2][3] if t[2][3]
            eql path2b.args,  t[2][4] if t[2][4]
            eql path2be.args, t[2][5] if t[2][5]


        it 'returns the value of the invoked function', ->
            v = null
            path ->
                v = path 'a', ->
                    return 42
                , ->
                    return 43
            eql v, null
            navigate 'a'
            eql v, 42
            navigate 'b'
            eql v, 43


        it 'is ok even if it fails', ->
            ok = false
            path ->
                path 'a', ->
                    throw new Error('failed')
                path 'b', ->
                    ok = true
            assert.throws (->navigate 'a'), 'failed'
            navigate 'b'
            eql ok, true

        it 'has only one root function', ->
            r = spy()
            path -> r 1
            path -> r 2
            navigate '/blah'
            eql r.args, [[2]]

        it 'returns navigate on root path', ->
            n = path ->
            assert n == navigate
