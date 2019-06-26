-----------------------------------------------------------------
-- 2019 Igor Suntsev
-- http://dragosha.com
-----------------------------------------------------------------

-- Share variables module


local M={
	-- perspective camera angle (deg) and factors for objects position corrections
	angle=-20,
	kZ=-1/3,
	kY=.91,

	--param.angle=-40
	--param.kZ=-1/1.5
	--param.kY=0.75

	--param.angle=-20
	--param.kZ=-1/3
	--param.kY=.91

	--param.angle=0
	--param.kZ=0
	--param.kY=1
	-------------------------------------
	-- hashes
	LEFT=hash("left"),
	RIGHT=hash("right"),
	UP=hash("up"),
	DOWN=hash("down"),
	CLICK=hash("click"),
	DODGE=hash("dodge"),
	JERK=hash("jerk"),
	DASH=hash("dash"),
	SLASH=hash("slash"),
	B=hash("B"),


	SOLID=hash("solid"),
	DEFAULT=hash("default"),
	ENEMY=hash("enemy"),
	HERO=hash("hero"),
	BULLET=hash("bullet"),

	TARGET_ID=hash("TARGET_ID"),
	PLEASESTOP=hash("PLEASESTOP"),

	DODAMAGE=hash("DODAMAGE"),
	GOTO=hash("GOTO"),
	LEVELLOADED=hash("LEVELLOADED")
}
return M