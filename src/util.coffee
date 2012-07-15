Function::method = (name, func) ->
    @prototype[name] = func
    this

Function.method('curry',
(head...) -> (tail...) => @apply(null, head.concat(tail)))

Number.method('integer',-> Math[if @ < 0 then 'ceil' else 'floor'](@))

if typeof Object.create != 'function'
    Object.create = (o) ->
        F = ->
        F.prototype = o
        new F()

any = (items) ->
    for item in items
        if item
            return true
    return false

all = (items) ->
    for item in items
        if not item
            return false
    return true

any_point =
    subtract : (v) -> point(@x - v.x, @y - v.y)
    joined : (separator) -> [String(@x), String(@y)].join(separator)
    csv : -> @joined(',')


point = (x, y) ->
    that = Object.create(any_point)
    that.x = Number(x)
    that.y = Number(y)
    that

dimensions = (box) -> point(box.width, box.height)

origin_by_name = (parent, name) ->
    e = parent.find("\##{name}")
    return point(e.attr('x'), e.attr('y'))

lib.util =
    any_point : any_point
    point : point
    dimensions : dimensions
    origin_by_name : origin_by_name
    any : any
    all : all
