-----------------------------------------------------------------
-- 2019 Igor Suntsev
-- http://dragosha.com
-----------------------------------------------------------------

local scene=require "main.scene"
local M={}

local raycast_request_id_counter = 0
local rayGroups={hash("default"),hash("solid")}

M.LEFT=-1
M.RIGHT=1
M.waypoints={}
M.onPosition={}


M.NONE=hash("none")
M.IDLE=hash("idle")
M.WALK=hash("walk")
M.HIT=hash("hit")
M.DIE=hash("die")
M.ATTACK=hash("attack")
M.PURSUIT=hash("pursuit")
M.WAIT=hash("wait")



function M.checkDirection(self)

	local targetPos = self.router.targetPos or go.get_position(self.router.targetID)
	local position = go.get_position()

		if targetPos.x<position.x-self.xAttackDif/10 then 
			self.direction=M.LEFT
		elseif targetPos.x>position.x+self.xAttackDif/10 then
			self.direction=M.RIGHT
		end

end

function M.modelFlip(self)
	if self.direction==M.LEFT then 
		go.set_rotation(vmath.quat_rotation_y(self.leftRotation),self.spineurl)
	elseif self.direction==M.RIGHT then
		go.set_rotation(vmath.quat_rotation_y(self.rightRotation),self.spineurl)
	end
end


function M.targetSeek(self)
	if not self.router.targetID then return end
	local targetPos = go.get_position(self.router.targetID)
	local position=go.get_position()
	position.z=0
	targetPos.z=0
	local len=vmath.length(position-targetPos)

	if self.melee then
		if 	targetPos.x>position.x-self.xAttackDif 	and
			targetPos.x<position.x+self.xAttackDif 	and
			targetPos.y<position.y+self.yAttackDif	and
			targetPos.y>position.y-self.yAttackDif 
		then
			self.onPosition=true 
			self.IseeTarget=true
			M.onPosition[self.ID]=true
			return
		else
			self.onPosition=false
			M.onPosition[self.ID]=nil
		end
	else
		if  len<self.attackRadius then
			self.onPosition=true 
			self.IseeTarget=true
			M.onPosition[self.ID]=true
			return
		else
			self.onPosition=false
			M.onPosition[self.ID]=nil
		end
	end

	

	local counter=0
	for k, v in pairs( M.onPosition ) do
		counter=counter+1
	end

	
	self.IseeTarget=false
	if len<self.maxRay and counter<3 then
		self.IseeTarget=true
		self.request_id = raycast_request_id_counter
		raycast_request_id_counter = raycast_request_id_counter + 1
		if raycast_request_id_counter>255 then raycast_request_id_counter=0 end

		-- outdated asynchronous method, need to update
		physics.ray_cast(position, targetPos, rayGroups, self.request_id)
	else
		self.router.targetPos=nil
	end


end

function M.raycastResponse(self, message)
	local saw= message.id==self.router.targetID
	if not saw then 

		
		local myPosition=go.get_position()
		local len=100000000
		local wp={}
		for i = 1, #M.waypoints do
			local p=M.waypoints[i]
			local l=vmath.length_sqr(myPosition-p.pos)
			if len>l and self.router.wayPoint~=p.id then
				len=l
				table.insert( wp, 1, p )
			end
		end

		local point = #wp>0 and wp[math.random( 1, math.min(#wp,3))] or nil
		if point then 
			self.router.targetPos=point.pos
			self.router.wayPoint=point.id
		else
			self.router.targetPos=nil
			self.router.wayPoint=nil
		end

	else
		self.router.targetPos=go.get_position(self.router.targetID)
		self.router.wayPoint=nil
	end

	M.checkDirection(self)
	M.modelFlip(self)

end




local custom_easing_value={0,1,1,1,0}
local custom_easing = vmath.vector(custom_easing_value)

function M.changeState(self,state,options)

	local function reset()
		self.stateTimer=0
		self.stateOptions=options
		scene.monsters[self.ID].state=self.state
	end

	if state == M.WALK and self.state ~= M.WALK then 
		self.state= M.WALK
		spine.play_anim(self.spineurl, "walk", go.PLAYBACK_LOOP_FORWARD, {blend_duration=.25, playback_rate=1+math.random()*.2})
		reset()
	elseif state == M.PURSUIT and self.state ~= M.PURSUIT then 
		self.state= M.PURSUIT
		spine.play_anim(self.spineurl, "walk", go.PLAYBACK_LOOP_FORWARD, {blend_duration=.25, playback_rate=1})
		reset()
	elseif state == M.IDLE and self.state ~= M.IDLE then 
		self.state= M.IDLE
		spine.play_anim(self.spineurl, "idle", go.PLAYBACK_LOOP_FORWARD, {blend_duration=.2, playback_rate=1+math.random()*.2-0.1})
		reset()
	elseif state == M.WAIT and self.state ~= M.WAIT then 
		self.state= M.WAIT
		self.vel.x=0
		self.vel.y=0
		self.walking=false
		spine.play_anim(self.spineurl, "idle", go.PLAYBACK_LOOP_FORWARD, {blend_duration=.1})
		reset()
	elseif state == M.HIT and self.state ~= M.HIT then 
		self.state= M.HIT
		self.vel.x=0
		self.vel.y=0
		--spine.set_constant(self.spineurl, "tint", vmath.vector4(1, 0, 0, 1))
		go.animate(self.spineurl, "tint", go.PLAYBACK_ONCE_FORWARD, vmath.vector4(80, 80, 80, 4), custom_easing, .2)
		spine.play_anim(self.spineurl, "hit", go.PLAYBACK_ONCE_FORWARD, {blend_duration=.25, playback_rate=1}, function()
		
			self.special=false
			self.state=M.NONE
		end)
		reset()
	elseif state == M.DIE and self.state ~= M.DIE then 
		self.state= M.DIE
		self.vel.x=0
		self.vel.y=0
		M.onPosition[self.ID]=nil
		self.die=true
		msg.post("#collisionobject", "disable")
		msg.post("#label", "disable")

		if self.router.seekID then timer.cancel(self.router.seekID) end
		if self.aiID then timer.cancel(self.aiID) end

		--go.animate(self.spineurl, "tint", go.PLAYBACK_ONCE_PINGPONG, vmath.vector4(1, 0, 1, 4), go.EASING_LINEAR, .25)
		go.animate(self.spineurl, "tint", go.PLAYBACK_ONCE_FORWARD, vmath.vector4(80, 80, 80, 4), custom_easing, .2)
		spine.play_anim(self.spineurl, "die", go.PLAYBACK_ONCE_FORWARD, {blend_duration=.25, playback_rate=1}, function()
			self.special=false
			
			--self.state=M.NONE
		end)
		reset()
	elseif state == M.ATTACK and self.state ~= M.ATTACK then 
		self.state= M.ATTACK
		local anim={"attack"}
		spine.play_anim(self.spineurl, anim[math.random(#anim)], go.PLAYBACK_ONCE_FORWARD, {blend_duration=.1, playback_rate=1}, function()
			self.special=false
			self.state=M.NONE
		end)
		reset()
	end

end

return M