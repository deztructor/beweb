fsm = lib.fsm
util = lib.util

test 'utilities', ->
    some_fn = (x, y) -> y + x
    plus42 = some_fn.curry(42)
    equal(typeof plus42, 'function', 'creating currying function')
    equal(plus42(1), 43, 'currying')
    plusa = some_fn.curry('+a')
    equal(plusa('b'), 'b+a', 'proper currying lambda creation')

    i1 = 12.5.integer()
    equal(i1, 12, 'integer() floor')
    i2 = -12.5.integer()
    equal(i2, -12, 'integer() ceil')

    base =
        a : -> 42
        b : 42
    derived = Object.create(base)
    notEqual(derived, base, "other object")
    ok(derived.a? and typeof derived.a == 'function', "has method a")
    equal(derived.a(), 42, "base method a is called")
    ok(derived.b?, "has variable a")
    equal(derived.b, 42, "base variable access")
    derived.a = -> 24
    equal(derived.a(), 24, "override base method a")

    equal(util.any([1, 2]), true)
    equal(util.any([false, 2]), true)
    equal(util.any([false, null]), false)

    equal(util.all([1, "x"]), true)
    equal(util.all([2, false]), false)
    equal(util.all([false, null]), false)

    p = util.point(3, 7)
    equal(p.x, 3)
    equal(p.y, 7)
    equal(p.joined(' '), '3 7')
    p2 = p.subtract(util.point(1, 2))
    equal(p2.x, 2)
    equal(p2.y, 5)
    equal(p2.csv(), '2,5')
    p3 = util.dimensions({width: 11, height: 13})
    equal(p3.x, 11)
    equal(p3.y, 13)
    


test 'basic fsm', ->
    states =
        initial :
            enter : -> @y = 13
            sum : -> @z = @x + @y
            exit : -> @z = 'initial_exit'
        state1 :
            enter : -> @x = 'in1'
            start : -> @transitions.state2()

        state2 :
            enter : -> @x = 'in2'

    expected_state_names = (name for name of states)
    foo = fsm { x : 121 }, states, 'initial'
    ok(foo.states?, "has states")
    ok(foo.transitions?, "has transitions")
    names =
    deepEqual((name for name of foo.states).sort(),
        expected_state_names.sort(), "state names")
    equal((x for x of foo.transitions).length,
        expected_state_names.length, "transitions")

    equal(foo.x, 121, "use base as this")
    equal(foo.y, 13, "enter action")
    foo.sum()
    equal(foo.z, foo.x + foo.y, "action for event")
    foo._go('state1')
    equal(foo.get_state().name, 'state1', "_go for state transition")
    equal(foo.z, 'initial_exit', "exit action")
    equal(foo.x, 'in1', "enter action")
    equal(foo.y, 13, "object state is not changed")
    foo.start()
    equal(foo.get_state().name, 'state2', 'transition on event')
    equal(foo.x, 'in2', 'enter action')
