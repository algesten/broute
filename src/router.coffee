window = require 'global/window'
query  = require './query'
lazy   = require './lazy'

isfun   = (f) -> typeof f == 'function'
isplain = (o) -> typeof o == 'object' and !Array.isArray(o)

mkdocheck = (win, listener) ->

    getloc = ->
        l = win?.location ? {}
        {pathname:l.pathname ? '', search:l.search ? ''}

    # the current location. starting
    # values that definitely will trigger
    loc = {pathname:null, search:null}

    ->
        next = getloc()
        if loc.pathname != next.pathname or loc.search != next.search
            loc = next
            listener(loc.pathname, query loc.search)


router = (win) ->

    throw new Error("router must be created around an object") unless isplain(win)

    # hoist
    run = proxy = docheck = ->

    # make a proxy that in turn produces a run function
    mkproxy = (frag, fn, fne) -> (path, search) ->
        _proxy = proxy # save for the future
        # find effective path/function
        [xp, xfn] = if path.indexOf(frag) == 0
            [path.substring(frag.length), fn]
        else
            [path, fne]
        # overwrite current proxy with one that immediatelly invokes
        # the run function with effective path
        proxy = (frag, fn, fne) -> mkproxy(frag, fn, fne)(xp, search)
        try
            # invoke the effective function
            xfn?(xp, search)
        finally
            # restore parent proxy
            proxy = _proxy

    # root level proxy just overwrites the starting point
    proxy = (frag, fn, fne) ->
        # root level run function
        run = lazy mkproxy frag, fn, fne
        # create a checker around the window
        docheck = mkdocheck win, run
        navigate # root level returns the navigate function

    # exposed path function which is proxying into mkrun
    path = (frag, fn, fne) ->
        if isfun frag
            fne = fn; fn = frag; frag = ''
        throw new Error("fragment must be a string") unless typeof frag == 'string'
        throw new Error("path function must be a function") unless isfun(fn)
        if fne
            throw new Error("path else function must be a function") unless isfun(fne)
        proxy frag, fn, fne

    # navigate function either working with pushState or win.location
    navigate = do ->
        ispush = isfun win?.history?.pushState
        (p) ->
            if arguments.length
                if ispush
                    win.history.pushState {}, null, p
                else
                    [_, pathname, search] = p?.match(/([^?]*)(\?.*)?/) ? []
                    win.location = {pathname:(pathname ? ''), search:(search ? '')}
            docheck()

    # when window changes state
    win?.addEventListener? 'popstate', -> docheck()

    {path, navigate}


# expose a default router for window
module.exports = Object.assign router, router(window)
