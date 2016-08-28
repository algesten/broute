
replaceplus = (s) -> s.replace /\+/g, ' '
decode      = (s) -> decodeURIComponent replaceplus s

# turns a search string ?a=b into an object {a:'b'}
module.exports = query = (s, ret = {}) ->
    unless s # null, undefined, false, ''
        ret
    else if s[0] in ['?', '&']
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
