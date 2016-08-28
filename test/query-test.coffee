
query = require '../src/query'

describe 'query', ->

    empties = [null, undefined, '', false, '&', '&&']
    for v in empties
        do (v) ->
            it "returns {} for '#{String(v)}'", -> eql query(v), {}

    tests =
        '?':       {'?':''}  #yes, correct
        '?&':      {'?':''}  #yes, correct
        '&?':      {'?':''}
        'a':       {a:''}
        '&a':      {a:''}
        '=a':      {a:''}
        '&=a':     {a:''}
        'a=':      {a:''}
        '?a=':     {'?a':''}
        'a=b':     {a:'b'}
        'a==b':    {a:'=b'}
        'a=b=':    {a:'b='}
        'a=b=c':   {a:'b=c'}
        'a=b&=':   {a:'b'}
        '&a=b&':   {a:'b'}
        'a=b&c':   {a:'b',c:''}
        'a=b&c=':  {a:'b',c:''}
        'a=b&c&':  {a:'b',c:''}
        'a=b&c=&': {a:'b',c:''}
        'a=b&c=d': {a:'b',c:'d'}
        'a=%20b':  {a:' b'}
        '%20a=b':  {' a':'b'}
        '&%20a=b': {' a':'b'}
        '&%20a=b&':{' a':'b'}
        'a=1&a=2': {a:['1','2']}
        'a=&a=1':  {a:['','1']}
    for k, v of tests
        do (k, v) ->
            it "returns #{JSON.stringify(v)} for '#{k}'", -> eql query(k), v
