# neocam

camera module for fnf

## vars

- `locked_pos` - target will be unchangeable if true
	- `bool`, default: `false`
- `pos_speed` - how fast the camera lerps to target pos
	- `number`, default: `8`
- `locked_offset` - disables note offset if true
	- `bool`, default: `false`
- `offset_mag` - note offset radius in pixels
	- `number`, default: `8`
- `shake_fps` - fps of shaking effect
	- `number`, default: `24`
- `locked_zoom` - zoom will be unchangeable if true (bumping not affected)
	- `bool`, default: `false`
- `zoom_speed` - how fast the camera lerps to target zoom
	- `number`, default: `2`
- `freeze` - completely stop neocam from doing anything
	- `bool`, default: `false`

## functions

- `set_target(tag:string, x:number, y:number)` - adds a target than can be focused on using the tag
- `focus(tag:string, duration:number, ease:string, lock:bool)` - move the camera to a target (with optional pos lock override)
- `snap_target(tag:string)` - instantly move the camera to a target (ignores lock)
- `shake(cam:string = "game", x:number, y:number, duration:number, ease:string)` - shake the camera
- `bump(cam:string = "game", amount:number)` - bump the camera
- `zoom(cam:string = "game", amount:number, duration:number, ease:string, lock:bool)` - zoom tween the camera (with optional zoom lock override)
- `snap_zoom(cam:string = "game", amount:number)` - instantly zoom the camera (ignores lock)

## events
note: bump amount is normalized; 1 = 1x default bump amount, 2 = 2x, etc

- `bump_speed` - set the camera bump strength and frequency (in beats)
	- v1: "modulo", `number`, default: `4`
	- v2: "amount", `number`, default: `1`
- `bump` - bump both cameras
	- v1: "game_amount", `number`, default: `1`
	- v2: "hud_amount", `number`, default: `2`
- `game_zoom` - zoom the game camera (sineinout easing)
	- v1: "amount", `number`, default: `(defaultCamZoom / 0.015)`
	- v2: "duration", `number`, default: `0`
- `hud_zoom` - zoom the hud camera (sineinout easing)
	- v1: "amount", `number`, default: `1`
	- v2: "duration", `number`, default: `0`
- `shake_game` - shake the game camera (1 second, cubeout easing)
	- v1: "x", `number`, default: `0`
	- v2: "y", `number`, default: `0`
- `shake_hud` - shake the hud camera (1 second, cubeout easing)
	- v1: "x", `number`, default: `0`
	- v2: "y", `number`, default: `0`
