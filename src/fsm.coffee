fsm_log = (args...) -> console.log.apply(console, args)

fsm_mk_handler = (that, name) ->
    (args...) ->
        state = that.get_state()
        if name of state
            state[name].apply(that, args)
        else
            fsm_log("No handler for #{name} in state #{state.name}");
            null

lib.fsm = (base, states, default_state) ->
    reserved_names = ['states', 'transitions', '_go']
    throw { err : "#{x} is reserved fsm member name" } \
    for x in reserved_names when x of base

    that = Object.create(base)
    that.states = states
    current_state = that.states[default_state]
    that.get_state = -> current_state

    go_state = (new_state) ->
        if "exit" of current_state
            current_state.exit.apply(that, [])
        current_state = new_state
        if "enter" of current_state
            current_state.enter.apply(that, [])
        that

    that._go = (name) -> go_state(that.states[name])

    that.transitions = {}
    for state_name, state of states
        that.transitions[state_name] = do ->
            () -> go_state(that.states[state_name])

        for member_name, member of state
            if typeof member != 'function'
                continue
            if (member_name in ['enter', 'exit']) or (member_name of that)
                continue
            that[member_name] = fsm_mk_handler(that, member_name)
        state.name = state_name

    if "enter" of current_state
        current_state.enter.apply(that, [])

    return that
