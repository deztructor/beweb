any_point = lib.util.any_point
point = lib.util.point

any_point.svg_translate = () -> "translate(#{@csv()})"
any_point.svg_point = () -> @joined(' ')


lib.SVG = (root) ->
    NS = 'http://www.w3.org/2000/svg'

    mk_playable = (target) ->
        target.is_playing = false
        target.play = () ->
            console.log("play", target.name)
            if target.is_playing
                console.log("already playing")
            else
                target.is_playing = true
                target.beginElement()
            target

        target.play_for = (timeout, on_done_cb = undefined) ->
            target.on_played = on_done_cb
            target.play()
            setTimeout(target.stop, timeout * 1000)
            target

        target.stop = () ->
            console.log("stop", target.name)
            if target.is_playing
                target.endElement()
                target.is_playing = false
            else
                console.log("do not need to stop");
            if target.on_played
                target.on_played(target)
                target.on_played = false

    mk_element = (element_name, default_target, name) ->
        result = document.createElementNS(NS, element_name)
        mk_playable(result)
        result.default_target = default_target
        result.name = name
        result

    bbox =
        cx : () -> @x + Math.floor(@w / 2)
        cy : () -> @y + Math.floor(@h / 2)
        C : -> point(@cx(), @cy())
        NW : -> point(@x, @y)
        N : -> point(@cx(), @y)
        NE : -> point(@x + @w, @y)
        E : -> point(@x + @w, @cy())
        SE : -> point(@x + @w, @y + @h)
        S : -> point(@cx(), @y + @h)
        SW : -> point(@x, @y + @h)
        W : -> point(@x, @cy())
        right : -> @x + @w
        bottom : -> @y + @h
        extend : (other) ->
            @x = Math.min(@x, other.x)
            @y = Math.min(@y, other.y)
            r = Math.max(@right(), other.right())
            b = Math.max(@bottom(), other.bottom())
            @w = r - @x
            @h = b - @y
            @
        from_SVGRect : (r) ->
            @x = r.x
            @y = r.y
            @w = r.width
            @h = r.height
            @
        from_DOMElement : (e) ->
            @w = e.clientWidth
            @h = e.clientHeight
            @x = e.offsetLeft
            @y = e.offsetTop
            @
        from_data : (x, y, w, h) ->
            @x = x
            @y = y
            @w = w
            @h = h
            @
    element_bbox = (e) ->
        result = Object.create(bbox)
        if 'getBBox' of e
            result.from_SVGRect(e.getBBox())
        else
            result.from_DOMElement(e)

    get_bbox = (e) ->
        if e.hasOwnProperty('length')
            boxes = (element_bbox(x) for x in e)
            [xs, ys, rs, bs] = [(b.x for b in boxes), (b.y for b in boxes),
            (b.r() for b in boxes), (b.b() for b in boxes)]
            [x, y, r, b] = [Math.min(xs...), Math.min(ys...),
            Math.max(rs...), Math.max(bs...)]
            res = Object.create(bbox)
            bbox.from_data(x, y, r - x, b - y)
        else
            element_bbox(element)

    center = (element) ->
        get_bbox(element).C()

    pole2center = (element, pole, spec) ->
        bb = get_bbox(element)
        spec.center = bb[pole]()
        spec

    animate = (svg_name, default_target, spec) ->
        that = mk_element(svg_name, default_target, spec.name)
        if !spec.duration
            throw {err : "Missing or wrong duration"}
        attr =
            id : spec.name
            repeatCount : spec.count || 'indefinite'
            dur : "#{spec.duration}s"
            begin : spec.begin || 'indefinite'
            additive : if spec.additive then spec.additive else 'replace'
            fill : if spec.fill then spec.fill else "freeze"
        if spec.keys
            attr.keySplines = spec.keys
        if spec.additive
            attr.additive = spec.additive

        (that.setAttribute(n, v) for n, v of attr)
        that.apply = () -> that.apply_to(that.default_target)
        that.apply_to = (e) ->
            if that.parentElement != e
                e.appendChild(that)
            that
        that.remove = () ->
            if that.parentElement
                root.remove(that)
        that

    animate_transform = (spec, default_target) ->
        that = animate('animateTransform', default_target, spec)
        attr = {attributeType : 'xml', attributeName : 'transform'}
        (that.setAttribute(n, v) for n, v of attr)
        that

    mk_animation_group = (name, elements) ->
        mk_fn = (fn_name) ->
            (args...) ->
                e[fn_name].apply(e, args) for e in that.elements
                that
        that =
            elements: elements
            name: name
            remove: mk_fn('remove')
            apply_to: mk_fn('apply_to')
            apply: mk_fn('apply')
            beginElement: mk_fn('beginElement')
            endElement: mk_fn('endElement')
            append: (element) ->
                that.elements.push(element)
                that

        mk_playable(that)
        that

    rotate_animation = (spec, default_target) ->
        that = animate_transform(spec, default_target)
        pos = spec.center.joined(' ')
        attr =
            type : 'rotate'
            to : "#{spec.to} #{pos}"
        if spec.hasOwnProperty('from')
            that.from = "#{spec.from} #{pos}"
        (that.setAttribute(n, v) for n, v of attr)
        that

    translate_animation = (spec, default_target) ->
        that = animate_transform(spec, default_target)
        attr =
            type : 'translate'
            to : spec.to.csv()
        if spec.hasOwnProperty('from')
            attr.from = spec.from.csv()
        (that.setAttribute(n, v) for n, v of attr)
        that

    scale_animation = (spec, default_target) ->
        that = animate_transform(spec, default_target)
        attr =
            type : 'scale'
            to : spec.to.csv()
        if spec.hasOwnProperty('from')
            attr.from = spec.from.csv()
        (that.setAttribute(n, v) for n, v of attr)
        that

    move_animation = (spec, default_target) ->
        that = animate('animateMotion', default_target, spec)
        path = spec.path
        that.setAttribute('path', spec.path)
        that

    append_animation = (ani_ctor, target, is_apply, spec) ->
        if (spec.pole)
            spec = pole2center(target, spec.pole, spec)
        res = ani_ctor(spec, target)
        if is_apply then res.apply() else res

    scale_around = (spec, default_target) ->
        if not 'center' of spec
            return scale_animation(spec, default_target)

        center = spec.center
        spec.additive = 'sum'
        t_spec = Object.create(spec)
        t_spec.from = point(-center.x * (spec.from.x - 1),
                            -center.y * (spec.from.y - 1))
        t_spec.to = point(-center.x * (spec.to.x - 1),
                          -center.y * (spec.to.y - 1))
        t_spec.name = "#{spec.name}-tr"
        delete spec.center
        mk_animation_group(spec.name
            [translate_animation(t_spec, default_target),
                scale_animation(spec, default_target)])

    path = (args...) ->
        parts = []
        if args.length == 1
            parts = parts.concat(arguments[0])

        that = -> parts.join(' ')

        E = (a) ->
            parts = parts.concat(a.join(' '))
            this

        that.M = (x, y) -> E(['M', x, y])
        that.L = (x, y) -> E(['L', x, y])
        that.C = (x1, y1, x2, y2, x, y) -> E(['C', x1, y1, x2, y2, x, y])
        that.Z = -> parts.push('Z'); that;
        that

    svgns =
        NS: NS
        rotate: append_animation.curry(rotate_animation)
        translate: append_animation.curry(translate_animation)
        move: append_animation.curry(move_animation)
        scale: append_animation.curry(scale_around)
        # returns animations array object resembling animation behavior
        animation_group : mk_animation_group
        bbox: get_bbox
        center: center
        path: path

    spec2animation = (target, is_apply, spec) ->
        fn = svgns[spec.source]
        params = [target, is_apply]
        if 'params' of spec
            params = params.concat spec.params
        params.push(spec.spec)
        fn.apply(svg, params)

    mk_animation = (target, is_apply, spec) ->
        if not ('source_type' of spec) or spec.source_type == "spec"
            spec2animation(target, is_apply, spec)
        else if spec.source_type == "function"
            spec.source.apply(svg, [target, is_apply])
        else
            throw { err : "Unrecognized source " + spec.source }

    svgns.animations_create = (spec, is_apply) ->
        if 'all' of spec
            throw { err : "Animation name can't be 'all'" }

         an_ani = (name, info) ->
            v = if info.target.length == 1
                mk_animation(info.target[0], is_apply, info)
            else
                mk_animation_group(name,
                    (mk_animation(v, is_apply, info) for v in info.target))
            [name, v]

        names_animations = (an_ani(name, info) for name, info of spec)
        res = new ->
            @[v[0]] = v[1] for v in names_animations
            this
        res.all = mk_animation_group("all", nth(1, names_animations))
        return res;

    return svgns
