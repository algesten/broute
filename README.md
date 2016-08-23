# broute - brutal router

### Router and Paths

#### route

`route(f)`

Declares the route function `f` which will be invoked each time the
url changes. There can only be one such function. The url is
"consumed" and "executed" using nested scoped
[`path`](#path)/[`exec`](#exec) functions.

`:: (() ->) -> undefined`

arg | desc
:---|:----
f   | The one and only route function.
ret | Always `undefined`

##### route usage

The following usage shows how nested `path` declarations creates
"scoped" functions that consumes part of the current url.

```coffee
# the current url is: "/some/path/deep?panda=42"

route ->

    path '/some', ->
        # at this point we "consumed" '/some'
        exec (part, query) ->
            # part is '/path'
            # query is {panda:42}

        path '/deep', ->
            exec (part, query) ->
                # part is ''
                # query is {panda:42}

    # at this point we haven't consumed anything
    exec (part, query) ->
        # part is '/some/path'
        # query is {panda:42}

    path '/another', ->
        # will not be invoked for the current url

```

##### route example

This tries to illustrate a more realistic example, including
[layout](#layout), [region](#region) and [action](#action).

```coffee
isItem = (part, query) -> part?.length > 1     # '' means list

route ->

    appview.top navbar          # show navbar view in top region
    appview.main homeview       # show home view in main region

    path '/news/', ->           # consume '/news/'
        if exec isItem                            # test if this is a news item
            exec (slugid) ->                      # use exec to get slugid from scoped path
                action 'selectarticle', slugid    # fire action to fetch article
                appview.main articleview          # show articleview in main region
        else
            action 'refreshnewslist'
            appview.main newslistview             # show newslist view in main region

    path '/aboutus', ->                           # consume '/aboutus'
        appview.main aboutusview                  # show aboutus view in main region
```

#### path

`path(p,f)`

As part of [`route`](#route) declares a function `f` that is invoked
if we "consume" url part `p` of the current (scoped) url.

arg | desc
:---|:----
p   | The string url part to match/consume.
f   | Function to invoke when url part matches.
ret | Always `undefined`

##### path example

See [route usage](#route-usage) and [route example](#route-example).

#### exec

`exec(f)`

As part of [`route`](#route) executes `f` with arguments
`(part,query)` for the current path scope.

arg | desc
:---|:----
f   | Function to invoke with `(part,query)`
ret | The result of the executed function.

##### exec example

See [route usage](#route-usage) and [route example](#route-example).

#### navigate

`navigate(l)`
`navigate(l, false)`

Navigates to the location `l` using [pushState][push] and checks to
see if the url changed in which case the [route function](#route) is
executed.

The function takes an optional second boolean argument that can be
used to supress the execution of the route function.

This function is lazy when used inside [route](#route), only the last
location will be used when the route function finishes.

`:: string -> undefined`
`:: string, boolean -> undefined`

arg | desc
:---|:----
l   | The (string) location to navigate to. Can be relative.
t   | Optional boolean set to false to supress route function triggering.
ret | always `undefined`

##### navigate example

```coffee
# if browser is at "http://my.host/some/where"

navigate 'other'    # changes url to "http://my.host/some/other"
navigate '/news'    # changes url to "http://my.host/news"


navigate '/didnt', false  # changes url to "http://my.host/didnt"
                          # without running the route function
```


License
-------

The MIT License (MIT)

Copyright © 2016 Martin Algesten

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[tagg]: https://github.com/algesten/tagg
[vdom]: https://github.com/Matt-Esch/virtual-dom
[push]: https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history#The_pushState()_method
[pages]: http://algesten.github.io/trifl/
