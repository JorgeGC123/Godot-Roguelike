extends Hitbox
class_name WeaponHitbox


func _on_Hitbox_area_entered(area: Area2D) -> void:
	#area.queue_free()
	print("coño")

func _collide(body: KinematicBody2D) -> void:
	if body != null and body != get_parent() and body.has_method("take_damage"):
		# Calculamos la dirección del knockback basada en la dirección del ataque
		knockback_direction = (body.global_position - get_parent().global_position).normalized()
		
		# Aplicamos el daño y knockback
		body.take_damage(damage, knockback_direction, knockback_force)
