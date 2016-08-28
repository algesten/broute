
describe 'route', ->

    router = reinit = route = path = navigate =
    _lazynavigate = _window = null

    beforeEach ->
        global.__TEST_ROUTER = true
        _window = global.window
        global.window =
            addEventListener: spy ->
            location:
                pathname: '/some/path'
                search:   '?a=b'
            history:
                pushState: spy ->
        {reinit} = require '../src/route'
        router = reinit?()
        {route, path, navigate, _lazynavigate} = router

    afterEach ->
        global.window = _window


    describe 'router', ->

        describe '_check', ->

            beforeEach ->
                router._run = stub().returns true
                router.loc.pathname = '/a/path'
                router.loc.search   = '?panda=true'

            it 'compares pathname/search and does nothing if they are the same', ->
                window.location.pathname = '/a/path'
                window.location.search   = '?panda=true'
                eql router._check(), false
                eql router._run.callCount, 0

            it 'compares pathname/search and invokes _run if pathname differs', ->
                window.location.pathname = '/another/path'
                window.location.search   = '?panda=true'
                eql router._check(), true
                eql router._run.callCount, 1
                eql router._run.args[0], ['/another/path', '?panda=true']

            it 'compares pathname/search and invokes _run if search differs', ->
                window.location.pathname = '/a/path'
                window.location.search   = '?kitten=true'
                eql router._check(), true
                eql router._run.callCount, 1
                eql router._run.args[0], ['/a/path', '?kitten=true']

        describe '_run', ->

            beforeEach ->
                router._consume = spy ->
                router._run '/a/path', '?panda=true'

            it 'accepts a null pathname', ->
                router._run null, '?panda=true'
                eql router.loc.pathname, '/'

            it 'accepts a null search', ->
                router._run '/', null
                eql router.loc.search, ''

            it 'updates the @loc object', ->
                eql router.loc.pathname, '/a/path'
                eql router.loc.search,   '?panda=true'

            it 'calls _consume with the path and parsed query', ->
                eql router._consume.callCount, 1
                eql router._consume.args[0], ['/a/path', 0, {panda:'true'}, router._route]

    describe 'navigate', ->

        beforeEach ->
            spy router, '_check'
            spy router, '_setLoc'

        it 'window.history.pushState it', ->
            navigate '/a/path?foo=bar'
            eql window.history.pushState.callCount, 1
            eql window.history.pushState.args[0], [{}, '', '/a/path?foo=bar']

        it '_check if the location has changed', ->
            navigate '/a/path?foo=bar'
            eql router._check.callCount, 1

        it 'doesnt _check if supressed', ->
            navigate '/b/path?foo=bar', false
            eql router._check.callCount, 0
            eql router._setLoc.callCount, 1

        it 'returns undefined', ->
            r = navigate '/a',
            eql r, undefined

    describe '_lazynavigate', ->

        beforeEach ->
            spy router, '_check'

        describe 'suspends navigation and', ->

            it 'does nothing unless a navigate while suspended', ->
                _lazynavigate true
                _lazynavigate false
                eql window.history.pushState.callCount, 0

            it 'defers the navigation until not suspended', ->
                _lazynavigate true
                navigate '/foo'
                eql window.history.pushState.callCount, 0
                _lazynavigate false
                eql window.history.pushState.callCount, 1
                eql window.history.pushState.args[0], [{}, '', '/foo']

            it 'uses the last navigate', ->
                _lazynavigate true
                navigate '/foo'
                navigate '/bar'
                eql window.history.pushState.callCount, 0
                _lazynavigate false
                eql window.history.pushState.callCount, 1
                eql window.history.pushState.args[0], [{}, '', '/bar']

            it 'also works for navigate(url, false)', ->
                _lazynavigate true
                navigate '/foo'
                navigate '/bar', false
                eql window.history.pushState.callCount, 0
                _lazynavigate false
                eql window.history.pushState.callCount, 1
                eql window.history.pushState.args[0], [{}, '', '/bar']
                eql router._check.callCount, 0

            it 'ignores empty navigate', ->
                _lazynavigate true
                navigate ''
                _lazynavigate false
                eql window.history.pushState.callCount, 0

    describe 'route/path', ->

        it 'outside route, nothing', ->
            path '/', r = spy ->
            eql r.callCount, 0

        it 'invoke route straight away', ->
            route r = spy()
            eql r.callCount, 1

        it 'route returns undefined', ->
            r = route ->
            eql r, undefined

        it 'path returns undefined', ->
            r = path ->
            eql r, undefined

        it 'invokes the route set', ->
            r = e = null
            window.location =
                pathname:'/a/path'
                search:'?foo=bar'
            route r = spy ->
            eql r.callCount, 1
            eql r.args[0], ['/a/path', foo:'bar']

        it 'invokes to the end and no more', ->
            s = r1 = r2 = e = null
            # default is "/some/path"
            route s = spy ->
                path '/a/path', ->
                    path '/', r1 = spy ->
                    path '', r2 = spy ->
            router._run '/a/path', '?foo=bar'
            eql s.callCount, 2
            eql r1.callCount, 0
            eql r2.callCount, 1
            eql r2.args[0], ['', foo:'bar']

        it 'path without match does nothing', ->
            r = null
            route -> path '/item', r = spy ->
            router._run '/a/path', '?foo=bar'
            eql r.callCount, 0

        it 'path consumes the route further', ->
            r = null
            route -> path '/item', r = spy ->
            router._run '/item/here', '?foo=bar'
            eql r.callCount, 1
            eql r.args[0], ['/here', foo:'bar']

        it 'path in path consumes the route further', ->
            r = e = null
            route -> path '/item', ->
                path '/is', r = spy ->
            router._run '/item/is/there', '?foo=bar'
            eql r.callCount, 1
            eql r.args[0], ['/there', foo:'bar']

        it 'path on the same level can match again', ->
            r1 = r2 = null
            route ->
                path '/item', r1 = spy ->
                path '/it', r2 = spy ->
            router._run '/item/here', '?foo=bar'
            eql r1.callCount, 1
            eql r1.args[0], ['/here', foo:'bar']
            eql r2.callCount, 1
            eql r2.args[0], ['em/here', foo:'bar']

        it 'path on the same level can match again after path in path', ->
            r1 = r2 = e1 = e2 = null
            route ->
                path '/item', ->
                    path '/he', r1 = spy ->
                path '/it', r2 = spy ->
            router._run '/item/here', '?foo=bar'
            eql r1.callCount, 1
            eql r1.args[0], ['re', foo:'bar']
            eql r2.callCount, 1
            eql r2.args[0], ['em/here', foo:'bar']

        describe 'path else', ->

            it 'executes if path doesnt match', ->
                correct = false
                r = null
                global.window.location = {pathname:'/about', search:''}
                route ->
                    path '/item', ->
                        throw Error()
                    , r = spy ->
                        correct = true
                eql correct, true
                eql r.args[0], ['/about', {}]

            it 'doesnt execute if path matches', ->
                correct = false
                global.window.location = {pathname:'/item/blah', search:''}
                route ->
                    path '/item', ->
                        correct = true
                    , ->
                        throw Error()
                eql correct, true

        describe 'lazynavigate', ->

            it 'suspends navigate during route function', ->
                r = null
                route -> path '/item', ->
                    navigate '/foo'
                    path '/is', r = spy ->
                        navigate '/bar'
                router._run '/item/is/there'
                eql r.callCount, 1
                eql window.history.pushState.callCount, 1
                eql window.history.pushState.args[0], [{}, '', '/bar']
