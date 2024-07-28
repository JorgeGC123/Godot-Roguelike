
class_name Entity
extends KinematicBody2D

var components: Dictionary = {}

func add_component(component_name: String, component: Component):
    components[component_name] = component
    add_child(component)
    component.initialize()

func get_component(component_name: String) -> Component:
    return components.get(component_name)

func process(delta: float):
    for component in components.values():
        component.update(delta)

func send_message(message: String, data: Dictionary = {}):
    for component in components.values():
        if component.has_method("receive_message"):
            component.receive_message(message, data)