-----------------------------------------------------------------
-- 2019 Igor Suntsev
-- http://dragosha.com
-----------------------------------------------------------------

local scene = require "main.scene"
local M = {}

local ray_groups = { hash("default"), hash("solid") }

M.LEFT = -1
M.RIGHT = 1
M.waypoints = {}
M.on_position = {}


M.NONE = hash("none")
M.IDLE = hash("idle")
M.WALK = hash("walk")
M.HIT = hash("hit")
M.DIE = hash("die")
M.ATTACK = hash("attack")
M.PURSUIT = hash("pursuit")
M.WAIT = hash("wait")



function M.check_direction(self)

	local target_pos = self.router.target_pos or go.get_position(self.router.target_id)
	local position = go.get_position()

		if target_pos.x < position.x - self.attack_radius_x / 10 then 
			self.direction = M.LEFT

		elseif target_pos.x > position.x+self.attack_radius_x / 10 then
			self.direction = M.RIGHT

		end

end

function M.model_flip(self)
	if self.direction == M.LEFT then 
		go.set_rotation(vmath.quat_rotation_y(self.left_rotation), self.spineurl)

	elseif self.direction == M.RIGHT then
		go.set_rotation(vmath.quat_rotation_y(self.right_rotation), self.spineurl)
	end

end


function M.target_seek(self)
	if not self.router.target_id then return end
	local target_pos = go.get_position(self.router.target_id)
	local position = go.get_position()
	position.z = 0
	target_pos.z = 0
	local len = vmath.length(position - target_pos)

	if self.melee then
		if 	target_pos.x > position.x - self.attack_radius_x and
			target_pos.x < position.x + self.attack_radius_x and
			target_pos.y < position.y + self.attack_radius_y and
			target_pos.y > position.y - self.attack_radius_y
		then
			self.on_position = true
			self.i_see_target = true
			M.on_position[self.ID] = true
			return

		else
			self.on_position = false
			M.on_position[self.ID] = nil
		end
	else
		if  len<self.attackRadius then
			self.on_position = true 
			self.i_see_target = true
			M.on_position[self.ID] = true
			return

		else
			self.on_position = false
			M.on_position[self.ID] = nil
		end
	end

	local counter = 0
	for k, v in pairs( M.on_position ) do
		counter = counter + 1
	end

	
	self.i_see_target = false
	if len < self.maxRay and counter < 3 then
		self.i_see_target = true

		local result = physics.raycast(position, target_pos, ray_groups)
		M.raycast_response(self, result)
	else
		self.router.target_pos = nil
	end


end

function M.raycast_response(self, result)
	local saw = (result.id or "") == self.router.target_id
	if not saw then 
		
		local my_position = go.get_position()
		local len = 100000000
		local wp = {}
		for i = 1, #M.waypoints do
			local p = M.waypoints[i]
			local l = vmath.length_sqr(my_position - p.pos)
			if len > l and self.router.waypoint ~= p.id then
				len = l
				table.insert( wp, 1, p )
			end
		end

		local point = #wp>0 and wp[math.random( 1, math.min(#wp,3) )] or nil
		if point then 
			self.router.target_pos = point.pos
			self.router.waypoint = point.id
		else
			self.router.target_pos = nil
			self.router.waypoint = nil
		end

	else
		self.router.target_pos = go.get_position(self.router.target_id)
		self.router.waypoint = nil
	end

	M.check_direction(self)
	M.model_flip(self)

end




local custom_easing_value = {0, 1, 1, 1, 0}
local custom_easing = vmath.vector(custom_easing_value)

function M.change_state(self, state, options)

	local function reset()
		self.state_timer = 0
		self.state_options = options
		scene.monsters[self.ID].state = self.state
	end

	if state == M.WALK and self.state ~= M.WALK then 
		self.state = M.WALK
		spine.play_anim(self.spineurl, "walk", go.PLAYBACK_LOOP_FORWARD, { blend_duration = 0.25, playback_rate = 1 + math.random() * 0.2 })
		reset()

	elseif state == M.PURSUIT and self.state ~= M.PURSUIT then 
		self.state = M.PURSUIT
		spine.play_anim(self.spineurl, "walk", go.PLAYBACK_LOOP_FORWARD, { blend_duration = 0.25, playback_rate = 1 })
		reset()

	elseif state == M.IDLE and self.state ~= M.IDLE then 
		self.state = M.IDLE
		spine.play_anim(self.spineurl, "idle", go.PLAYBACK_LOOP_FORWARD, { blend_duration = 0.2, playback_rate = 0.9 + math.random() * 0.2 })
		reset()

	elseif state == M.WAIT and self.state ~= M.WAIT then 
		self.state = M.WAIT
		self.vel.x = 0
		self.vel.y = 0
		self.walking = false
		spine.play_anim(self.spineurl, "idle", go.PLAYBACK_LOOP_FORWARD, { blend_duration = 0.1 })
		reset()

	elseif state == M.HIT and self.state ~= M.HIT then 
		self.state = M.HIT
		self.vel.x = 0
		self.vel.y = 0
		--spine.set_constant(self.spineurl, "tint", vmath.vector4(1, 0, 0, 1))
		go.animate(self.spineurl, "tint", go.PLAYBACK_ONCE_FORWARD, vmath.vector4(80, 80, 80, 4), custom_easing, 0.2)
		spine.play_anim(self.spineurl, "hit", go.PLAYBACK_ONCE_FORWARD, { blend_duration = 0.25, playback_rate = 1 },
			function()
				self.special = false
				self.state = M.NONE
			end)
		reset()

	elseif state == M.DIE and self.state ~= M.DIE then 
		self.state = M.DIE
		self.vel.x = 0
		self.vel.y = 0
		M.on_position[self.ID] = nil
		self.die = true
		msg.post("#collisionobject", "disable")
		msg.post("#label", "disable")

		if self.router.seek_id then timer.cancel(self.router.seek_id) end
		if self.ai_id then timer.cancel(self.ai_id) end

		--go.animate(self.spineurl, "tint", go.PLAYBACK_ONCE_PINGPONG, vmath.vector4(1, 0, 1, 4), go.EASING_LINEAR, 0.25)
		go.animate(self.spineurl, "tint", go.PLAYBACK_ONCE_FORWARD, vmath.vector4(80, 80, 80, 4), custom_easing, 0.2)
		spine.play_anim(self.spineurl, "die", go.PLAYBACK_ONCE_FORWARD, { blend_duration = 0.25, playback_rate = 1 },
			function()
				self.special = false
				--self.state = M.NONE
			end)
		reset()

	elseif state == M.ATTACK and self.state ~= M.ATTACK then 
		self.state = M.ATTACK
		local anim = {"attack"}
		spine.play_anim(self.spineurl, anim[math.random(#anim)], go.PLAYBACK_ONCE_FORWARD, { blend_duration = 0.1, playback_rate = 1 },
			function()
				self.special = false
				self.state = M.NONE
			end)
		reset()

	end

end

return M