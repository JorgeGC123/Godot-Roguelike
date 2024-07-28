class_name FSMComponent
extends Component

var states: Dictionary = {}
var previous_state: int = -1
var state: int = -1 setget set_state

signal state_changed(previous_state, new_state)

func _init(entity: Node).(entity):
    pass

func initialize():
    pass

func update(delta: float):
    if state != -1:
        _state_logic(delta)
        var transition = _get_transition()
        if transition != -1:
            set_state(transition)

func _state_logic(_delta: float):
    pass

func _get_transition() -> int:
    return -1

func _add_state(new_state: String):
    states[new_state] = states.size()

func set_state(new_state: int):
    _exit_state(state)
    previous_state = state
    state = new_state
    _enter_state(previous_state, state)
    emit_signal("state_changed", previous_state, state)

func _enter_state(_previous_state: int, _new_state: int):
    pass

func _exit_state(_state_exited: int):
    pass

func get_current_state() -> String:
    for state_name in states.keys():
        if states[state_name] == state:
            return state_name
    return ""

func get_state(state_name: String) -> bool:
    return state == states.get(state_name, -1)