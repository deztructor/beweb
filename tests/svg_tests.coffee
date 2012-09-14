point = lib.util.point

root = null
svg = null

#scene = $("#svgload").svg('get');

prepare_svg = (ctx) ->
    f = ctx.rect(20, 30, 80, 100,
    {fill: 'none', stroke: 'red', strokeWidth: 1, id: 'figure'})
    #f.setAttribute "id", "figure"
    f = [
        ctx.rect(60, 90, 70, 48,
        {fill: 'none', stroke: 'green', strokeWidth: 2}),
        ctx.rect(50, 40, 10, 120,
        {fill: 'none', stroke: 'blue', strokeWidth: 4})
        ]
    (x.setAttribute("class", "pair") for x in f)
    r = ctx.rect(100, 120, 40, 60,
    {fill: 'none', stroke: 'black', strokeWidth: 2, id: 'rotated'})
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
    deepEqual([b.x, b.y, b.w, b.h], [20, 30, 80, 100], "correct bounds")
    deepEqual(svg.center(f), point(60, 80), "center check")

    f = $('.pair')
    equal(f.length, 2, "there should be 2 in pair")
    b = svg.bbox(f)
    ok(b, "got bounding box")
    deepEqual([b.x, b.y, b.w, b.h], [50, 40, 80, 120], "correct bounds")
    deepEqual(svg.center(f), point(90, 100), "center check")

assert_selector = (element, selector) ->
    equal($(selector, element).length, 1, "has '#{selector}'")

assert_playable = (element) ->
    fns = ['play', 'play_for', 'stop']
    (ok(k of element, k) for k in fns)

test 'svg rotate', ->
    ok root, "root is here"
    ok svg, "svg lib is ok"

    basic = (to, pole, duration, cx, cy) ->
        name = "to_#{to}_around_#{pole}"
        {
            spec :
                name : name
                from: 0, to: to
                duration: duration
                pole: pole
            attrs :
                attributeName : "transform"
                attributeType : "xml"
                id : name
                type : "rotate"
                repeatCount : "indefinite"
                dur : "#{duration}s"
                begin : "indefinite"
                additive : "replace"
                fill : "freeze"
                to : "#{to} #{cx} #{cy}"
        }

    f = $('#rotated')
    equal(f.length, 1, "need #rotated")

    b = svg.bbox(f)
    [l, t, r, b] = [b.x, b.y, b.right(), b.bottom()]
    [cx, cy] = [(l + r) / 2, (t + b) / 2]
    items = [
        basic(45, 'C', 0.011, cx, cy)
        basic(46, 'W', 0.012, l, cy)
        basic(47, 'E', 0.013, r, cy)
        basic(48, 'N', 0.015, cx, t)
        basic(49, 'S', 0.016, cx, b)
    ]

    test_step = (data) ->

        ani = svg.rotate(f, true, data.spec)

        attrs = data.attrs
        (assert_selector(f, x) for x in ['animateTransform', "##{attrs.id}"])
        e = $('animateTransform', f)[0]

        console.log attrs.id
        (ok(e.hasAttribute(k), k) for k of attrs)
        (equal(e.getAttribute(k), v, "#{k}=#{v}") for k, v of attrs)

        #assert_playable(ani)
        ani.remove()

    (test_step(x) for x in items)
