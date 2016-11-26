# broute - brutal router

[![Build Status](https://travis-ci.org/algesten/broute.svg?branch=master)](https://travis-ci.org/algesten/broute)

```javascript
import {path, navigate} from 'broute'
```

## path

`path(f)`  
`path(p,f)`  
`path(p,f,fe)`

Tests the given part fragment `p` and if current path matches,
consumes the fragment and invokes function `f`. If not match, no
consume and invoke optional function `fe`.

* `p` - path fragment to match from current scope
* `f` - function to invoke if fragment matches
* `fe` - optional "else" function to invoke if fragment doesnt match
* return - the result of `f` or `fe`

## vararg paths to test

`path(p1,f1,p2,f2,...,pn,fn,fe)`

Any number of paths can be tested and the first one that matches is run.

### function args

The `f` or `fe` is invoked with `(left, query)`. The first is the path
that is left after the `p` fragment has been consumed (not for `fe`).

* `left` - the path that is left after consuming fragment `p`
* `search` - the search parameters as object `?a=b` becomes `{a:'b'}`

### root 

On the root level, we can use path without a string arg. This is the
starting point of the route function that is invoked for every url
change. There can only be one root level path installed for each router.

```
path(() => {

})
```

#### path usage

The following usage shows how nested `path` declarations creates
"scoped" functions that consumes part of the current url.

```javascript
// the current url is: "/some/path/deep?panda=42"

path(() => {

    path('/some', (left, query) => {
        // at this point we "consumed" '/some'
        // and left is "/path/deep"
        // and query is {panda:42}
        path('/path/deep', (left, query) => {
          // left is "" and query is {panda:42}
        })
    })
    // at this point we haven't consumed anything
    path('/another', () => {
        // will not be invoked for the current url
    })
})
```

#### path example 2

```javascript
path(() => {

    path('/news/', (slugId) => {                  // consume '/news/'
        action('selectarticle', slugid)           // fire action to fetch article
    }, () => {
        action('refreshnewslist')                 // else refresh news list
    })
    path('/aboutus', () => {                      // consume '/aboutus'
        action('showaboutus')
    })
})
```

## navigate

`navigate(l)`  

Navigates to the location `l` using [pushState][push] and checks to
see if the url changed in which case the [path function](#path) is
invoked. 

* `l` - location to set. example `/my/page?foo=42`

#### navigate example

```javascript
// if browser is at "http://my.host/some/where"

navigate('other')   // changes url to "http://my.host/some/other"
navigate('/news')   // changes url to "http://my.host/news"
```

### lazy

`navigate` is lazy when used inside a path. in this example, only `/a`
and `/c` would be run. Furthermore the invocation of `/c` only happens
at the end of the root path function.

```javascript
path(() => {
    navigate("/b")
    navigate("/c")
    if (someCondition()) {
        ... // more code
    }
    // conceptually navigate("/c") happens here
})  
navigate("/a")
```

## Creating routers

For advanced usages, new routers can be created around arbitrary
"window" objects.

Conceptually broute does this for the default `path` and `navigate`
functions around a current global `window` variable:

```javascript
import router from 'broute'         // router function

{path, navigate} = router(window)  // create a router around window
```

If the `window` argument has an `addEventListener` function, a
listener will be added for [`popstate`][popstate] events. This means
broute will run the path function also for the back button as well as
via `navigate`.

On each `popstate` or `navigate` invocation, the `window` argument
is inspected for a property `window.location` which is expected to
hold an object:

```
{
  pathname: "/current/path", 
  search:   "?my=query"
}
```

If this object changes on `navigate` or `popstate`, the path function
is run.

If the `window` doesn't have a `window.history.pushState` function, `navigate`
will fall back on manipulating `window.location` directly.


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

[push]: https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history#The_pushState()_method
[popstate]: https://developer.mozilla.org/en-US/docs/Web/Events/popstate
