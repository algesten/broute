
module.exports = (fn) ->
    running = false
    last = null
    wrap = (as...) ->
        if running
            last = as
            return
        try
            running = true
            fn as...
        finally
            running = false
            if last
                _last = last
                last = null
                wrap _last...
    Object.assign wrap, fn
    wrap
