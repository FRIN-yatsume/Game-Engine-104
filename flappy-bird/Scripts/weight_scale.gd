# 共享的体重/档位缩放公式（鸟与水管 loss 档位共用）
class_name WeightScale


# --- 缩放倍率 ---
static func visual_scale(value: int, per_step: float) -> float:
	return 1.0 + (maxi(value, 1) - 1) * per_step


static func collision_scale(value: int, per_step: float) -> float:
	return 1.0 + (maxi(value, 1) - 1) * per_step


# --- 换算为像素宽度 ---
static func visual_width(value: int, base_texture_width: float, per_step: float) -> float:
	return base_texture_width * visual_scale(value, per_step)


static func collision_width(value: int, base_collision_diameter: float, per_step: float) -> float:
	return base_collision_diameter * collision_scale(value, per_step)
