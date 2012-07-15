point = lib.util.point

root = null
svg = null

#scene = $("#svgload").svg('get');

prepare_svg = (ctx) ->
    f = ctx.rect 20, 30, 80, 100, {fill: 'none', stroke: 'red', strokeWidth: 3}
    f.setAttribute "id", "figure"
    root = ctx


$(document).ready ->
    $('#svgload').svg {onLoad: prepare_svg}

asyncTest 'svg loaded', ->
    counter = 100
    root_is_available = ->
        if root
            ok true, "root is loaded"
            svg = lib.SVG(root)
            start()
        else if counter == 0
            ok false, "no root"
        else
            --counter
            setTimeout root_is_available, 20
    root_is_available()

test 'svg info', ->
    ok root, "root is here"
    ok svg, "svg lib is ok"
    f = $('#figure')
    equal(f.length, 1, "figure exists")
    b = svg.bbox(f)
    ok(b, "got bounding box")
    bbox = [b.x, b.y, b.w, b.h]
    deepEqual(bbox, [20, 30, 80, 100], "correct bounding box")
    deepEqual(svg.center(f), point(60, 80), "right center")
