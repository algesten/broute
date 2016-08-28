I          = (v) -> v
builtin    = I.bind.bind I.call
startswith = (s, i) -> s.slice(0, i.length) == i
indexof    = builtin String::indexOf

query = require './query'

# encapsulates the router functions
class Router

    loc:   null  # saved location for comparison in _check()
    _route: ->   # saved route function
    _path: null  # path function replaced for every _consume

    constructor: (@win) ->
        @win.addEventListener 'popstate', @_check, false
        @loc = {}

    _consume: (loc, pos, qu, fun) =>
        sub = loc.substring pos
        spath = @_path
        @_path = (p, f, fe) =>
            if startswith(sub, p)
                @_consume loc, pos + p.length, qu, f
                true
            else
                fe?(sub, qu)
                false
        try
            if fun(sub, qu)
                return true
            else
                return false
        finally
            @_path = spath

    _check: =>
        {pathname, search} = @win.location
        return false if @loc.pathname == pathname and @loc.search == search
        @_run pathname, search

    _run: (pathname = '/', search = '') ->
        @_setLoc pathname, search
        q = query if search[0] == '?' then search[1..] else search
        try
            @_lazynavigate true
            @_consume pathname, 0, q, @_route
        finally
            @_lazynavigate false

    _setLoc: (pathname = '/', search = '') ->
        @loc.pathname = pathname
        @loc.search   = search

    navigate: (url, trigger = true) =>
        if @_lazynav
            @_lazynav = [url, trigger] if url
        else
            @win.history.pushState {}, '', url
            if trigger
                @_check()
            else
                {pathname, search} = @win.location
                @_setLoc pathname, search
        return undefined

    _lazynavigate: (suspend) =>
        if suspend
            @_lazynav = '__NOT'
        else
            args = @_lazynav
            delete @_lazynav
            @navigate args... unless args == '__NOT'

    route: (f)    =>
        @_route = f
        #reset
        @loc = {}
        # and start again
        router._check()
        return undefined

    path:  (p, f, fe) => @_path?(p, f, fe)

# singleton
router = null
do init = ->
    `router = new Router(window)`

module.exports = {
    route:router.route, path:router.path, navigate:router.navigate,
    _lazynavigate:router._lazynavigate
}

# expose router/reinit for tests
if global?.__TEST_ROUTER
    module.exports.query = query
    module.exports.router = router
    module.exports.reinit = init
