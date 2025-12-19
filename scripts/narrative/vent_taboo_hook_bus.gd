extends Node
class_name VentTabooHookBus

signal taboo_triggered(taboo_id: String)

func trigger(taboo_id: String) -> void:
    emit_signal("taboo_triggered", taboo_id)
