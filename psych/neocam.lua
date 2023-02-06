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
local cur = {0, 0}
local offset = {{0, 0}, {0, 0}}
local shaking = {{0, 0}, {0, 0}, 0}
local zooms = {1, 1}
local bumping = {4, 1}

function set_target(tag, x, y) targets[tag] = {x, y} end

function focus(tag, duration, ease, lock)
	local target = targets[tag]
	if target then
		if lock == false then locked_pos = lock end
		if not locked_pos then
			if lock == true then locked_pos = lock end
			if duration <= 0.01 then
				cancelTween("ncfx")
				cancelTween("ncfy")
				setProperty("ncf.x", target[1])
				setProperty("ncf.y", target[2])
			else
				doTweenX("ncfx", "ncf", target[1], duration, ease)
				doTweenY("ncfy", "ncf", target[2], duration, ease)
			end
		end
	end
end

function snap_target(tag)
	local target = targets[tag]
	if target then
		cur = {target[1], target[2]}
		setProperty("camFollowPos.x", cur[1])
		setProperty("camFollowPos.y", cur[2])
		setProperty("ncf.x", cur[1])
		setProperty("ncf.y", cur[2])
	end
end

function shake(cam, x, y, duration, ease)
	if duration > 0.01 then
		cam = cam == "game" and "g" or "h"
		
		if x and x ~= 0 then
			setProperty("ncs" .. cam .. ".x", x)
			doTweenX("ncs" .. cam .. "x", "ncs" .. cam, 0, duration, ease)
		end
		
		if y and y ~= 0 then
			setProperty("ncs" .. cam .. ".y", y)
			doTweenY("ncs" .. cam .. "y", "ncs" .. cam, 0, duration, ease)
		end
	end
end

function bump(cam, amount)
	cam = cam == "game" and 1 or 2
	zooms[cam] = zooms[cam] + amount * 0.015
end

function zoom(cam, amount, duration, ease, lock)
	cam = cam == "game" and 1 or 2
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
	cam = cam == "game" and 1 or 2
	zooms[cam] = amount
	cancelTween("ncz" .. cam)
	setProperty("ncz" .. cam .. ".x", amount)
end

function onCreatePost()
	targets = {
		opp = {
			getMidpointX("dad") + 150 + getProperty("dad.cameraPosition[0]") + getProperty("opponentCameraOffset[0]"),
			getMidpointY("dad") - 100 + getProperty("dad.cameraPosition[1]") + getProperty("opponentCameraOffset[1]")
		},
		
		plr = {
			getMidpointX("boyfriend") - 100 - getProperty("boyfriend.cameraPosition[0]") + getProperty("boyfriendCameraOffset[0]"),
			getMidpointY("boyfriend") - 100 + getProperty("boyfriend.cameraPosition[1]") + getProperty("boyfriendCameraOffset[1]")
		}
	}
	
	set_target("center", (targets.opp[1] + targets.opp[1]) / 2, (targets.opp[2] + targets.opp[2]) / 2)
	
	makeLuaSprite("ncf", nil, 0, 0)
	snap_target("center")
	setProperty("isCameraOnForcedPos", true)
	
	makeLuaSprite("ncsg", nil, 0, 0)
	makeLuaSprite("ncsh", nil, 0, 0)
	
	zooms[1] = getProperty("defaultCamZoom")
	makeLuaSprite("nczg", nil, zooms[1], 0)
	makeLuaSprite("nczh", nil, 1, 0)
end

function onSongStart()
	focus(mustHitSection and "plr" or "opp", 1.25, "cubeout")
	bump("game", bumping[2])
	bump("hud", bumping[2] * 2)
end

function onSectionHit() focus(mustHitSection and "plr" or "opp", 1.25, "cubeout") end
function onStepHit()
	if curStep % (bumping[1] * 4) == 0 then
		bump("game", bumping[2])
		bump("hud", bumping[2] * 2)
	end
end

local function follow_note(direction)
	if locked_offset then
		offset[1] = {0, 0}
	else
		local horizontal = direction == 0 or direction == 3
		offset[1] = {
			horizontal and (direction == 0 and -offset_mag or offset_mag) or 0,
			horizontal and 0 or (direction == 1 and offset_mag or -offset_mag)
		}
	end
end

function goodNoteHit(id, direction) if mustHitSection then follow_note(direction) end end
function opponentNoteHit(id, direction) if not mustHitSection then follow_note(direction) end end

local events = {
	bump_speed = function(modulo, amount)
		bumping = {tonumber(modulo) or 4, tonumber(amount) or 1}
	end,
	
	bump = function(game_amount, hud_amount)
		bump("game", tonumber(game_amount) or 1)
		bump("hud", tonumber(hud_amount) or 2)
	end,
	
	game_zoom = function(amount, duration)
		amount = tonumber(amount) or (getProperty("defaultCamZoom") / 0.015)
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

function onEvent(name, v1, v2) if events[name] then events[name](v1, v2) end end

function onUpdatePost(elapsed)
	if not frozen then
		local alpha = min(max(elapsed * pos_speed, 0), 1)
		
		debugPrint(elapsed)
		debugPrint(pos_speed)
		debugPrint(alpha)
		debugPrint("_________")
		
		if locked_offset then offset[1] = {0, 0} end
		
		offset[2] = {lerp(offset[2][1], offset[1][1], alpha), lerp(offset[2][2], offset[1][2], alpha)}
		
		shaking[3] = shaking[3] + elapsed
		if shaking[3] > 1 / shake_fps then
			shaking = {
				{getRandomInt(-1, 1) * getProperty("ncsg.x"), getRandomInt(-1, 1) * getProperty("ncsg.y")},
				{getRandomInt(-1, 1) * getProperty("ncsh.x"), getRandomInt(-1, 1) * getProperty("ncsh.y")},
				shaking[3] % (1 / shake_fps)
			}
		end
		
		cur = {lerp(cur[1], getProperty("ncf.x") + offset[2][1], alpha), lerp(cur[2], getProperty("ncf.y") + offset[2][2], alpha)}
		
		alpha = min(max(elapsed * zoom_speed, 0), 1)
		zooms[1] = lerp(zooms[1], getProperty("nczg.x"), alpha)
		zooms[2] = lerp(zooms[2], getProperty("nczh.x"), alpha)
		
		setProperty("camFollowPos.x", cur[1] + shaking[1][1])
		setProperty("camFollowPos.y", cur[2] + shaking[1][2])
		setProperty("camHUD.x", shaking[2][1])
		setProperty("camHUD.y", shaking[2][2])
		
		setProperty("camGame.zoom", zooms[1])
		setProperty("camHUD.zoom", zooms[2])
	end
end

function onGameOverStart()
	cameraShake("game", 0.01, 0.1)
	frozen = true
end