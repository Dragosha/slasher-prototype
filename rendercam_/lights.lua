local lights = {}

local IDENTITY_MATRIX = vmath.matrix4()

function lights.create_render_target(name)
	local color_params = { 
		format = render.FORMAT_RGBA,
		width = render.get_window_width(),
		height = render.get_window_height(),
		min_filter = render.FILTER_LINEAR,
		mag_filter = render.FILTER_LINEAR,
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE
	}

	local depth_params = {
		format = render.FORMAT_DEPTH,
		width = render.get_window_width(),
		height = render.get_window_height(),
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE
	}
	return render.render_target(name, {[render.BUFFER_COLOR_BIT] = color_params })
	--return render.render_target(name, {[render.BUFFER_COLOR_BIT] = color_params, [render.BUFFER_DEPTH_BIT] = depth_params })
end

function lights.create_render_targets(self)
	self.normal_rt = lights.create_render_target("normal")
	self.light_rt = lights.create_render_target("light")
end


function lights.clear(color, depth, stencil)
	if depth then
		render.set_depth_mask(true)
	end
	
	if stencil then
		render.set_stencil_mask(0xff)
	end
	render.clear({[render.BUFFER_COLOR_BIT] = color, [render.BUFFER_DEPTH_BIT] = depth, [render.BUFFER_STENCIL_BIT] = stencil})
end

function lights.render_to_world(self, predicates, constants)

	render.set_depth_mask(false)
	render.disable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.disable_state(render.STATE_CULL_FACE)
	render.enable_state(render.STATE_BLEND)
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)

	for _,pred in ipairs(predicates) do
		render.draw(pred, constants)
	end
end

function lights.render_to_rt(self, render_target, render_fn)
	render.enable_render_target(render_target)
	render_fn(self)
	render.disable_render_target(render_target)
end


function lights.mix_to_quad(self, rt0, rt1)
	render.set_depth_mask(false)
	render.disable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.disable_state(render.STATE_CULL_FACE)
	render.enable_state(render.STATE_BLEND)
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)

	render.enable_material(hash("mix_quad"))
	render.enable_texture(0, rt0, render.BUFFER_COLOR_BIT)
	render.enable_texture(1, rt1, render.BUFFER_COLOR_BIT)
	render.draw(self.quad_pred)
	render.disable_texture(0, rt0)
	render.disable_texture(1, rt1)
	render.disable_material()
end

function lights.multiply_to_quad(self, rt0, rt1)
	render.set_depth_mask(false)
	render.disable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.disable_state(render.STATE_CULL_FACE)
	render.enable_state(render.STATE_BLEND)
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)

	render.enable_material(hash("multiply_quad"))
	render.enable_texture(0, rt0, render.BUFFER_COLOR_BIT)
	render.enable_texture(1, rt1, render.BUFFER_COLOR_BIT)
	render.draw(self.quad_pred)
	render.disable_texture(0, rt0)
	render.disable_texture(1, rt1)
	render.disable_material()
end

function lights.draw_to_quad(self, rt)
	render.set_depth_mask(false)
	render.disable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.disable_state(render.STATE_CULL_FACE)
	render.enable_state(render.STATE_BLEND)
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)

	render.enable_material(hash("quad"))
	render.enable_texture(0, rt, render.BUFFER_COLOR_BIT)
	render.draw(self.quad_pred)
	render.disable_texture(0, rt)
	render.disable_material()
end


function lights.render_to_quad(self, fn)
	render.set_view(IDENTITY_MATRIX)
	render.set_projection(IDENTITY_MATRIX)
	fn(self)
end

return lights