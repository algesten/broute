window = require 'global/window'
query  = require './query'
lazy   = require './lazy'

isfun   = (f) -> typeof f == 'function'
isstr   = (s) -> typeof s == 'string'
isplain = (o) -> typeof o == 'object' and !Array.isArray(o)

mkdocheck = (win, listener) ->

    getloc = ->
        l = win?.location ? {}
        {pathname:l.pathname ? '', search:l.search ? ''}

    # the current location. starting
    # values that definitely will trigger
    loc = {pathname:null, search:null}

    docheck = ->
        next = getloc()
        if loc.pathname != next.pathname or loc.search != next.search
            loc = next
            listener(loc.pathname, query loc.search)

    # expose method to just update state
    docheck.update = -> loc = getloc()

    # the actual function
    docheck

router = (win) ->

    throw new Error("router must be created around an object") unless isplain(win)

    # hoist
    run = proxy = docheck = ->

    # make a proxy that in turn produces a run function
    mkproxy = (fragfn) -> (path, search) ->
        _proxy = proxy # save for the future
        try
            # iterate over pairs until we find the first to execute
            for [frag, fn] in fragfn
                # match?
                continue unless path.indexOf(frag) == 0
                xp = path.substring(frag.length)
                # overwrite current proxy with one that immediatelly invokes
                # the run function with effective path
                proxy = (fragfn) -> mkproxy(fragfn)(xp, search)
                # invoke the effective function
                return fn(xp, search)
            return undefined
        finally
            # restore parent proxy
            proxy = _proxy

    # root level proxy just overwrites the starting point
    proxy = (fragfn) ->
        # root level run function
        run = lazy mkproxy(fragfn)
        # create a checker around the window
        docheck = mkdocheck win, run
        navigate # root level returns the navigate function

    # exposed path function which is proxying into mkrun
    path = (as...) -> proxy parseargs(as)

    parseargs = (as) ->
        fragfn = [] # argument pairs

        if as.length == 1
            # single argument is root
            throw new Error("xarg 0 must be a function") unless isfun(as[0])
            fragfn.push ['',as[0]]
        else
            # odd length, last one is an else
            fne = null  # else
            if as.length % 2 == 1
                fne = as.pop()
                throw new Error("path else function must be a function") unless isfun(fne)

            for a1, i in as by 2
                a2 = as[i + 1]
                throw new Error("arg #{i} must be a string") unless isstr(a1)
                throw new Error("arg #{i + 1} must be a function") unless isfun(a2)
                fragfn.push [a1,a2]

            # else last
            fragfn.push ['', fne] if fne

        # the parsed args array
        fragfn

    # navigate function either working with pushState or win.location
    navigate = do ->
        ispush = isfun win?.history?.pushState
        (p, trigger=true) ->
            if arguments.length
                if ispush
                    win.history.pushState {}, null, p
                else
                    [_, pathname, search] = p?.match(/([^?]*)(\?.*)?/) ? []
                    win.location = {pathname:(pathname ? ''), search:(search ? '')}
            if trigger
                # run full check
                docheck()
            else
                # just ensure state is updated
                docheck.update()

    # when window changes state
    win?.addEventListener? 'popstate', -> docheck()

    {path, navigate}


# expose a default router for window
module.exports = Object.assign router, router(window)
