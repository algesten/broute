I          = (v) -> v
builtin    = I.bind.bind I.call
startswith = (s, i) -> s.slice(0, i.length) == i
indexof    = builtin String::indexOf

replaceplus = (s) -> s.replace /\+/g, ' '
decode      = (s) -> decodeURIComponent replaceplus s

# turns a search string ?a=b into an object {a:'b'}
query = (s, ret = {}) ->
    unless s # null, undefined, false, ''
        ret
    else if s[0] == '&'
        query s[1..], ret
    else
        [m, key, val] = s.match(/([^&=]+)=?([^&]*)/) || ['']
        if key
            dkey = decode key
            dval = decode val
            if (prev = ret[dkey])?
                arr = if Array.isArray(prev) then prev else ret[dkey] = [prev]
                arr.push decode(val)
            else
                ret[dkey] = dval
        query s.substring(m.length + 1), ret

# encapsulates the router functions
class Router

    loc:   null  # saved location for comparison in _check()
    _route: ->   # saved route function
    _path: null  # path function replaced for every _consume

    constructor: (@win) ->
        @win.addEventListener 'popstate', @_check, false
        @loc = {}

    _consume: (loc, pos, query, fun) =>
        sub = loc.substring pos
        spath = @_path
        @_path = (p, f, fe) =>
            if startswith(sub, p)
                @_consume loc, pos + p.length, query, f
                true
            else
                fe?(sub, query)
                false
        try
            if fun(sub, query)
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
