--[[ neocam by cyn ]]

locked_pos = false
pos_speed = 8

locked_offset = false
offset_mag = 8
shake_fps = 24

locked_zoom = false
zoom_speed = 2

freeze = false

-- internal

local min = math.min
local max = math.max
local function lerp(start, goal, alpha) return start + (goal - start) * alpha end

local targets = {}
local cur = {x = 0, y = 0}
local offset = {{x = 0, y = 0}, {x = 0, y = 0}}
local shaking = {g = {x = 0, y = 0}, h = {x = 0, y = 0}, t = 0}
local zooms = {g = 1, h = 1}
local bumping = {mod = 4, a = 1}

function set_target(tag, x, y) targets[tag] = {x = x, y = y} end

function focus(tag, duration, ease, lock)
	local target = targets[tag]
	if target then
		if lock == false then locked_pos = lock end
		if not locked_pos then
			if lock == true then locked_pos = lock end
			if duration <= 0.01 then
				cancelTween("ncfx")
				cancelTween("ncfy")
				setProperty("ncf.x", target.x)
				setProperty("ncf.y", target.y)
			else
				doTweenX("ncfx", "ncf", target.x, duration, ease)
				doTweenY("ncfy", "ncf", target.y, duration, ease)
			end
		end
	end
end

function snap_target(tag)
	local target = targets[tag]
	if target then
		cur = {x = target.x, y = target.y}
		setProperty("camFollowPos.x", cur.x)
		setProperty("camFollowPos.y", cur.y)
		setProperty("ncf.x", cur.x)
		setProperty("ncf.y", cur.y)
	end
end

function shake(cam, x, y, duration, ease)
	cam = cam == "game" and "g" or "h"
	
	if x then
		cancelTween("ncs" .. cam .. "x")
		setProperty("ncs" .. cam .. ".x", x)
		if duration > 0.01 then
			doTweenX("ncs" .. cam .. "x", "ncs" .. cam, 0, duration, ease)
		end
	end
	
	if y then
		cancelTween("ncs" .. cam .. "y")
		setProperty("ncs" .. cam .. ".y", y)
		if duration > 0.01 then
			doTweenY("ncs" .. cam .. "y", "ncs" .. cam, 0, duration, ease)
		end
	end
end

function bump(cam, amount)
	cam = cam == "game" and "g" or "h"
	zooms[cam] = zooms[cam] + amount * 0.015
end

function zoom(cam, amount, duration, ease, lock)
	cam = cam == "game" and "g" or "h"
	if lock == false then locked_zoom = lock end
	if not locked_zoom then
		if lock == true then locked_zoom = lock end
		if duration <= 0.01 then
			cancelTween("ncz" .. cam)
			setProperty("ncz" .. cam .. ".x", amount)
		else
			doTweenX("ncz" .. cam, "ncz" .. cam, amount, duration, ease)
		end
	end
end

function snap_zoom(cam, amount)
	cam = cam == "game" and "g" or "h"
	zooms[cam] = amount
	cancelTween("ncz" .. cam)
	setProperty("ncz" .. cam .. ".x", amount)
end

function onCreatePost()
	set_target("opp",
		getMidpointX("dad") + 150 + getProperty("dad.cameraPosition[0]") + getProperty("opponentCameraOffset[0]"),
		getMidpointY("dad") - 100 + getProperty("dad.cameraPosition[1]") + getProperty("opponentCameraOffset[1]")
	)
	
	set_target("plr",
		getMidpointX("boyfriend") - 100 - getProperty("boyfriend.cameraPosition[0]") + getProperty("boyfriendCameraOffset[0]"),
		getMidpointY("boyfriend") - 100 + getProperty("boyfriend.cameraPosition[1]") + getProperty("boyfriendCameraOffset[1]")
	)
	
	set_target("center", (targets.opp.x + targets.plr.x) / 2, (targets.opp.y + targets.plr.y) / 2)
	
	makeLuaSprite("ncf", nil, 0, 0)
	snap_target("center")
	setProperty("isCameraOnForcedPos", true)
	
	makeLuaSprite("ncsg", nil, 0, 0)
	makeLuaSprite("ncsh", nil, 0, 0)
	
	zooms.g = getProperty("defaultCamZoom")
	makeLuaSprite("nczg", nil, zooms.g, 0)
	makeLuaSprite("nczh", nil, 1, 0)
end

function onSongStart()
	focus(mustHitSection and "plr" or "opp", 1.25, "cubeout")
	bump("game", bumping.a)
	bump("hud", bumping.a * 2)
end

function onSectionHit() focus(mustHitSection and "plr" or "opp", 1.25, "cubeout") end
function onStepHit()
	if curStep % (bumping.mod * 4) == 0 then
		bump("game", bumping.a)
		bump("hud", bumping.a * 2)
	end
end

local function follow_note(direction)
	if locked_offset then
		offset[1] = {x = 0, y = 0}
	else
		local horizontal = direction == 0 or direction == 3
		offset[1] = {
			x = horizontal and (direction == 0 and -offset_mag or offset_mag) or 0,
			y = horizontal and 0 or (direction == 1 and offset_mag or -offset_mag)
		}
	end
end

function goodNoteHit(id, direction) if mustHitSection then follow_note(direction) end end
function opponentNoteHit(id, direction) if not mustHitSection then follow_note(direction) end end

local events = {
	bump_speed = function(modulo, amount)
		bumping = {mod = tonumber(modulo) or 4, a = tonumber(amount) or 1}
	end,
	
	bump = function(game_amount, hud_amount)
		bump("game", tonumber(game_amount) or 1)
		bump("hud", tonumber(hud_amount) or 2)
	end,
	
	game_zoom = function(amount, duration)
		amount = tonumber(amount) or getProperty("defaultCamZoom")
		duration = tonumber(duration) or 0
		duration = duration < 0 and 0 or duration
		zoom("game", amount, duration, "sineinout")
	end,
	
	hud_zoom = function(amount, duration)
		amount = tonumber(amount) or 1
		duration = tonumber(duration) or 0
		duration = duration < 0 and 0 or duration
		zoom("hud", amount, duration, "sineinout")
	end,
	
	shake_game = function(x, y)
		x = tonumber(x) or 0
		y = tonumber(y) or 0
		shake("game", x, y, 1, "cubeout")
	end,
	
	shake_hud = function(x, y)
		x = tonumber(x) or 0
		y = tonumber(y) or 0
		shake("hud", x, y, 1, "cubeout")
	end,
}

function onEvent(tag, v1, v2) if events[tag] then events[tag](v1, v2) end end

function onUpdatePost(elapsed)
	if not frozen then
		local alpha = min(max(elapsed * pos_speed, 0), 1)
		
		if locked_offset then offset[1] = {x = 0, y = 0} end
		offset[2] = {x = lerp(offset[2].x, offset[1].x, alpha), y = lerp(offset[2].y, offset[1].y, alpha)}
		
		shaking.t = shaking.t + elapsed
		if shaking.t > 1 / shake_fps then
			shaking = {
				g = {x = getRandomInt(-1, 1) * getProperty("ncsg.x"), y = getRandomInt(-1, 1) * getProperty("ncsg.y")},
				h = {x = getRandomInt(-1, 1) * getProperty("ncsh.x"), y = getRandomInt(-1, 1) * getProperty("ncsh.y")},
				t = shaking.t % (1 / shake_fps)
			}
		end
		
		cur = {x = lerp(cur.x, getProperty("ncf.x") + offset[2].x, alpha), y = lerp(cur.y, getProperty("ncf.y") + offset[2].y, alpha)}
		
		alpha = min(max(elapsed * zoom_speed, 0), 1)
		zooms.g = lerp(zooms.g, getProperty("nczg.x"), alpha)
		zooms.h = lerp(zooms.h, getProperty("nczh.x"), alpha)
		
		setProperty("camFollowPos.x", cur.x + shaking.g.x)
		setProperty("camFollowPos.y", cur.y + shaking.g.y)
		setProperty("camGame.zoom", zooms.g)
		
		setProperty("camHUD.x", shaking.h.x)
		setProperty("camHUD.y", shaking.h.y)
		setProperty("camHUD.zoom", zooms.h)
	end
end

function onGameOverStart()
	cameraShake("game", 0.01, 0.1)
	frozen = true
end
