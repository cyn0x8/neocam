stop = false

follow_speed = 8
zoom_speed = 2

position_locked = false
offset_locked = false

offset_magnitude = 5

local targets = {
	["song name here"] = {
		dad = {x = 0, y = 0},
		bf = {x = 0, y = 0},
		-- custom = {x = 0, y = 0},
		-- ...
	},
	-- ...
}

local cur, offset = {x = 0, y = 0}, {{x = 0, y = 0}, {x = 0, y = 0}}
local zooms, bumping = {game = 1, hud = 1}, {modulo = 4, amount = 1}

function set_target(tag, x, y) targets[tag] = {x = x, y = y} end
function focus(tag, duration, ease, lock)
	local target = targets[tag]
	if target then
		if lock == false then position_locked = lock end
		if not position_locked then
			if lock == true then position_locked = lock end
			if duration <= 0.01 then cancelTween("ncfollow_x"); setProperty("ncfollow.x", target.x); cancelTween("ncfollow_y"); setProperty("ncfollow.y", target.y)
			else doTweenX("ncfollow_x", "ncfollow", target.x, duration, ease); doTweenY("ncfollow_y", "ncfollow", target.y, duration, ease) end
		end
	end
end
function snap_target(tag)
	local target = targets[tag]
	if target then
		cur = {x = target.x, y = target.y}
		setProperty("camFollowPos.x", cur.x); setProperty("camFollowPos.y", cur.y)
		setProperty("ncfollow.x", cur.x); setProperty("ncfollow.y", cur.y)
	end
end

function bump(camera, amount) if zooms[camera] then zooms[camera] = zooms[camera] + amount end end
function zoom(camera, amount, duration, ease)
	camera = camera:lower(); camera = camera:sub(1, 3) == "cam" and camera:sub(4, -1) or camera
	if zooms[camera] then
		if duration <= 0.01 then cancelTween("nczoom" .. camera); setProperty("nczoom" .. camera .. ".x", amount)
		else doTweenX("nczoom" .. camera, "nczoom" .. camera, amount, duration, ease) end
	end
end
function snap_zoom(camera, amount)
	camera = camera:lower(); camera = camera:sub(1, 3) == "cam" and camera:sub(4, -1) or camera
	if zooms[camera] then
		zooms[camera] = amount
		cancelTween("nczoom" .. camera); setProperty("nczoom" .. camera .. ".x", amount)
	end
end

function onCreatePost()
	targets = targets[songName:lower()] or {
		dad = {x = getMidpointX("dad") + 150 + getProperty("dad.cameraPosition[0]") + getProperty("opponentCameraOffset[0]"), y = getMidpointY("dad") - 100 + getProperty("dad.cameraPosition[1]") + getProperty("opponentCameraOffset[1]")},
		bf = {x = getMidpointX("boyfriend") - 100 - getProperty("boyfriend.cameraPosition[0]") + getProperty("boyfriendCameraOffset[0]"), y = getMidpointY("boyfriend") - 100 + getProperty("boyfriend.cameraPosition[1]") + getProperty("boyfriendCameraOffset[1]")}
	}
	set_target("center", (targets.dad.x + targets.bf.x) / 2, (targets.dad.y + targets.bf.y) / 2)
	
	makeLuaSprite("ncfollow", nil, 0, 0)
	snap_target("center"); setProperty("isCameraOnForcedPos", true)
	
	zooms.game = getProperty("defaultCamZoom")
	makeLuaSprite("nczoomgame", nil, zooms.game, 0); makeLuaSprite("nczoomhud", nil, 1, 0)
	
	for i = 0, getProperty("eventNotes.length") - 1 do
		if getPropertyFromGroup("eventNotes", i, "event") == "bump_speed" then
			local time = getPropertyFromGroup("eventNotes", i, "strumTime")
			if time <= stepCrochet then bumping = {modulo = tonumber(getPropertyFromGroup("eventNotes", i, "value1")) or 4, amount = tonumber(getPropertyFromGroup("eventNotes", i, "value2")) or 1}
			else setPropertyFromGroup("eventNotes", i, "strumTime", time - 25) end
		end
	end
end

function onSongStart()
	focus(mustHitSection and "bf" or "dad", 1.25, "cubeout")
	bump("game", bumping.amount * 0.015); bump("hud", bumping.amount * 0.03)
end
function onSectionHit() focus(mustHitSection and "bf" or "dad", 1.25, "cubeout") end
function onStepHit() if curStep % (bumping.modulo * 4) == 0 then bump("game", bumping.amount * 0.015); bump("hud", bumping.amount * 0.03) end end

local function follow_note(direction)
	if offset_locked then offset[1] = {x = 0, y = 0} else
		local horizontal = direction == 0 or direction == 3
		offset[1] = {x = horizontal and (direction == 0 and -offset_magnitude or offset_magnitude) or 0, y = horizontal and 0 or (direction == 1 and offset_magnitude or -offset_magnitude)}
	end
end
function goodNoteHit(id, direction) if mustHitSection then follow_note(direction) end end
function opponentNoteHit(id, direction) if not mustHitSection then follow_note(direction) end end

local events = {
	bump_speed = function(v1, v2) bumping = {modulo = tonumber(v1) or (curStep + 1) / 4, amount = tonumber(v2) or 1} end,
	bump = function(v1, v2) bump("game", tonumber(v1) or 0.015); bump("hud", tonumber(v2) or 0.03) end,
	game_zoom = function(v1, v2) v1, v2 = tonumber(v1) or getProperty("defaultCamZoom"), tonumber(v2) or 0; v2 = v2 < 0 and 0 or v2; zoom("game", v1, v2, "sineinout") end,
	hud_zoom = function(v1, v2) v1, v2 = tonumber(v1) or 1, tonumber(v2) or 0; v2 = v2 < 0 and 0 or v2; zoom("hud", v1, v2, "sineinout") end
}
function onEvent(name, v1, v2) if events[name] then events[name](v1, v2) end end

local min, max = math.min, math.max
local function lerp(start, goal, alpha) return start + (goal - start) * alpha end
function onUpdatePost(elapsed)
	if not stop then
		local alpha = min(max(elapsed * follow_speed, 0), 1)
		if offset_locked then offset[1] = {x = 0, y = 0} end
		offset[2] = {x = lerp(offset[2].x, offset[1].x, alpha), y = lerp(offset[2].y, offset[1].y, alpha)}
		cur = {x = lerp(cur.x, getProperty("ncfollow.x") + offset[2].x, alpha), y = lerp(cur.y, getProperty("ncfollow.y") + offset[2].y, alpha)}
		
		alpha = min(max(elapsed * zoom_speed, 0), 1)
		zooms.game = lerp(zooms.game, getProperty("nczoomgame.x"), alpha)
		zooms.hud = lerp(zooms.hud, getProperty("nczoomhud.x"), alpha)
		
		setProperty("camFollowPos.x", cur.x); setProperty("camFollowPos.y", cur.y)
		setProperty("camGame.zoom", zooms.game); setProperty("camHUD.zoom", zooms.hud)
	end
end

function onGameOverStart()
	cameraShake("game", 0.01, 0.1)
	stop = true
end