package main

import "core:fmt"
import m "core:math/linalg/hlsl"
import rnd "core:math/rand"
import rl "vendor:raylib"

Game :: struct {
	title:    string,
	entities: [dynamic]Entity,
}

Window :: struct {
	name:   cstring,
	width:  i32,
	height: i32,
	fps:    i32,
}

Entity :: struct {
	type:    EntityType,
	pos:     m.float2,
	col:     rl.Color,
	variant: union {
		^P1,
		^P2,
		^Ball,
	},
}

P1 :: struct {
	using entity: Entity,
	spd:          f32,
	scr:          i32,
	dim:          m.float2,
	shape:        rl.Rectangle,
	hit:          bool,
}

P2 :: struct {
	using entity: Entity,
	spd:          f32,
	scr:          i32,
	dim:          m.float2,
	shape:        rl.Rectangle,
	hit:          bool,
}

Ball :: struct {
	using entity: Entity,
	vel:          m.float2,
	r:            f32,
}

Theme :: struct {
	bg_main, txt_dark, txt_light, p1, p2, ball: rl.Color,
}

theme: Theme

State :: enum {
	LOGO,
	TITLE,
	GAME,
	END,
}

EntityType :: enum {
	P1,
	P2,
	BALL,
}

main :: proc() {
	// Initialise
	game := Game {
		title    = "Sqong",
		entities = make([dynamic]Entity),
	}
	defer delete(game.entities)

	window := Window{"Sqong", WIN_DIM.x, WIN_DIM.y, 60}
	rl.InitWindow(window.width, window.height, window.name)
	rl.SetTargetFPS(window.fps)

	currentScreen := State.LOGO
	framesCounter := 0

	theme.bg_main = CHAMPAGNE
	theme.txt_dark = MUDDY
	theme.txt_light = SANDY
	theme.p1, theme.p2 = BLUEISH, BLUEISH
	theme.ball = RED

	p1 := entityMake(P1)
	p2 := entityMake(P2)
	p1.type = .P1
	p2.type = .P2
	defer free(p1)
	defer free(p2)

	ball := entityMake(Ball)
	ball.type = .BALL
	defer free(ball)

	append(&game.entities, p1)
	append(&game.entities, p2)
	append(&game.entities, ball)

	entityPopulate(&game)

	rl.InitAudioDevice()
	strike_fx1 = rl.LoadSound("./assets/hit5.ogg") // paddle
	strike_fx2 = rl.LoadSound("./assets/hit2.ogg") // wall
	strike_fx3 = rl.LoadSound("./assets/hit4.ogg") // spin
	score_fx1 = rl.LoadSound("./assets/score3.ogg") // P1
	score_fx2 = rl.LoadSound("./assets/score4.ogg") // CPU
	back_fx1 := rl.LoadMusicStream("./assets/tuneSynth.ogg") // Game
	back_fx2 := rl.LoadMusicStream("./assets/tuneFullLargeWithGap.ogg") // Title
	rl.SetSoundVolume(strike_fx1, 0.4)

	Paused: bool = false

	// Loop
	for !rl.WindowShouldClose() {

		if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {Paused = !Paused}

		// State
		switch currentScreen 
		{
		case .LOGO:
			{
				framesCounter += 1

				if framesCounter > 120 {
					currentScreen = State.TITLE
				}
			};break
		case .TITLE:
			{
				rl.PlayMusicStream(back_fx2)
				rl.UpdateMusicStream(back_fx2)

				if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
					currentScreen = State.GAME
				}
			};break
		case .GAME:
			{
				rl.StopMusicStream(back_fx2)
				rl.UpdateMusicStream(back_fx1)
				rl.PlayMusicStream(back_fx1)

				if !Paused {
					rl.SetMusicVolume(back_fx1, 0.8)
				} else {
					rl.SetMusicVolume(back_fx1, 0.2)
				}

				if rl.IsKeyDown(rl.KeyboardKey.X) || p1.scr == MAX_SCORE || p2.scr == MAX_SCORE {
					currentScreen = State.END
				} else if rl.IsKeyDown(rl.KeyboardKey.B) {
					debugShow(ball)
				}
			};break
		case .END:
			{
				rl.StopMusicStream(back_fx1)

				if rl.IsKeyDown(rl.KeyboardKey.ENTER) {
					currentScreen = State.GAME
				}
			};break
		}

		// Render
		rl.BeginDrawing()

		rl.ClearBackground(theme.bg_main)

		switch currentScreen 
		{
		case .LOGO:
			{
				drawLogo()
			};break
		case .TITLE:
			{
				drawTitle()
			};break
		case .GAME:
			{
				drawNet()

				drawScores(p1, p2)

				drawBall(ball)

				if !Paused {

					playerControls(p1)

					drawP1(p1)
					drawP2(p2)

					cpuAI(p2, ball)

					setBoundaries(p1, p2)

					moveBall(ball)

					p1.hit = false
					p2.hit = false

					collisionLogic(p1, p2, ball)

					scoreLogic(p1, p2, ball)

					trackWinner(p1, p2)
				}

				if Paused {
					rl.DrawText(
						"Paused",
						WIN_DIM.x / 2 - rl.MeasureText("Paused", 40) / 2,
						WIN_DIM.y / 2,
						40,
						theme.txt_dark,
					)
				}

			};break
		case .END:
			{
				drawEndScreen()
				p1.scr = MIN_SCORE
				p2.scr = MIN_SCORE
			};break
		}

		rl.EndDrawing()
	}

	rl.UnloadSound(score_fx1)
	rl.UnloadSound(score_fx2)
	rl.UnloadSound(strike_fx1)
	rl.UnloadSound(strike_fx2)
	rl.UnloadSound(strike_fx3)
	rl.UnloadMusicStream(back_fx1)
	rl.UnloadMusicStream(back_fx2)

	rl.CloseWindow()
}

WIN_DIM :: m.int2{600, 400}

CHAMPAGNE :: rl.Color{255, 221, 163, 255}
MUDDY :: rl.Color{115, 86, 63, 255}
SANDY :: rl.Color{127, 106, 79, 255}
BLUEISH :: rl.Color{121, 173, 160, 255}
RED :: rl.Color{244, 16, 6, 255}

X_MEAN: f32 : 2.8
X_SDEV: f32 : 0.3
Y_MEAN: f32 : 0.5
Y_SDEV: f32 : 0.2

DAMP_WALL: f32 : 0.7
DAMP_SPIN: f32 : 0.8
ACCEL_SPIN: f32 : 1.5

BALL_RADIUS: f32 : 10.0
BALL_SPEED_MULT: f32 : 1.1

P1_START_POS: i32 : 30
P2_START_POS: i32 : 555
PLAYERS_WIDTH: f32 : 15.0
PLAYERS_HEIGHT: f32 : 60.0
P1_SPEED: f32 = 2.0
CPU_SPEED: f32 = 1.5

MIN_SCORE: i32 : 0
MAX_SCORE: i32 : 4
scoreCounter: i32 = 0
winner: string = "It's a draw!"

strike_fx1: rl.Sound
strike_fx2: rl.Sound
strike_fx3: rl.Sound
score_fx1: rl.Sound
score_fx2: rl.Sound

entityMake :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
	return e
}

entityInstance :: proc(entity: ^Entity, game: ^Game) {
	switch entity.type {
	case .P1:
		fmt.println("hello p1")
		entity.variant.(^P1).dim = m.float2{PLAYERS_WIDTH, PLAYERS_HEIGHT}
		entity.variant.(^P1).scr = MIN_SCORE
		entity.pos = m.float2{f32(P1_START_POS), f32(WIN_DIM.y / 2)}
		entity.variant.(^P1).spd = P1_SPEED
		entity.variant.(^P1).shape = {
			f32(entity.pos.x),
			f32(entity.pos.y),
			entity.variant.(^P1).dim.x,
			entity.variant.(^P1).dim.y,
		}
		entity.col = theme.p1
	case .P2:
		fmt.println("hello p2")
		entity.variant.(^P2).dim = m.float2{PLAYERS_WIDTH, PLAYERS_HEIGHT}
		entity.variant.(^P2).scr = MIN_SCORE
		entity.pos = m.float2{f32(P2_START_POS), f32(WIN_DIM.y / 2)}
		entity.variant.(^P2).spd = CPU_SPEED
		entity.variant.(^P2).shape = {
			f32(entity.pos.x),
			f32(entity.pos.y),
			entity.variant.(^P2).dim.x,
			entity.variant.(^P2).dim.y,
		}
		entity.col = theme.p2
	case .BALL:
		fmt.println("hello ball")
		entity.pos = {f32(WIN_DIM.x / 2), f32(WIN_DIM.y / 2)}
		entity.variant.(^Ball).r = BALL_RADIUS
		entity.variant.(^Ball).vel = m.float2{
			rnd.float32_normal(X_MEAN, X_SDEV),
			rnd.float32_normal(Y_MEAN, Y_SDEV),
		}
	}
}

entityPopulate :: proc(game: ^Game) {
	fmt.println("🏓entities populated🏓")
	for _, i in game.entities {
		entityInstance(&game.entities[i], game)
	}
}

debugShow :: proc(ball: ^Ball) {
	rl.DrawText(rl.TextFormat("%f", ball.vel), WIN_DIM.x - 150, WIN_DIM.y - 25, 20, rl.RED)
	rl.DrawFPS(25, WIN_DIM.y - 25)
}

drawLogo :: proc() {
	rl.DrawText("SQONG", 20, 20, 40, theme.txt_light)
	rl.DrawText(
		"Loading...",
		WIN_DIM.x / 2 - rl.MeasureText("Loading...", 20) / 2,
		200,
		20,
		theme.txt_dark,
	)
}

drawTitle :: proc() {
	rl.DrawText("SQONG", 20, 20, 40, theme.txt_light)
	rl.DrawText("Controls: W (up), S (down), SPACE (pause), X (quit)", 20, 120, 20, theme.txt_dark)
	rl.DrawText("Start game: ENTER", 20, 170, 20, theme.txt_dark)
	rl.DrawText("Rules: P1 on left, score 4 to win", 20, 220, 20, theme.txt_dark)
	rl.DrawText("Close game: ESC", 20, 270, 20, theme.txt_dark)
	rl.DrawText("DeBug info: hold B", 20, 320, 20, theme.txt_dark)
}

drawNet :: proc() {
	for i: i32 = 0; i < WIN_DIM.y; i += 5 {
		rl.DrawPixel(WIN_DIM.x / 2, i, theme.txt_dark)
	}
}

drawScores :: proc(p1: ^P1, p2: ^P2) {
	rl.DrawText(rl.TextFormat("%i", p1.scr), 10, WIN_DIM.y / 10, 20, theme.txt_dark)
	rl.DrawText(rl.TextFormat("%i", p2.scr), WIN_DIM.x - 20, WIN_DIM.y / 10, 20, theme.txt_dark)
}

playerControls :: proc(p1: ^P1) {
	if rl.IsKeyDown(rl.KeyboardKey.W) {
		p1.shape.y -= p1.spd
	}
	if rl.IsKeyDown(rl.KeyboardKey.S) {
		p1.shape.y += p1.spd
	}
}

cpuAI :: proc(p2: ^P2, ball: ^Ball) {
	if (p2.shape.y + p2.dim.y / 2) > ball.pos.y && ball.vel.x > 0 {
		p2.shape.y -= p2.spd
	} else if (p2.pos.y > ball.pos.y) && ball.vel.x < 0 {
		p2.shape.y -= p2.spd / 3
	} else if (p2.shape.y + p2.dim.y / 2) < ball.pos.y && ball.vel.x > 0 {
		p2.shape.y += p2.spd
	} else if p2.shape.y < ball.pos.y && ball.vel.x < 0 {
		p2.shape.y += p2.spd / 3
	}
}

setBoundaries :: proc(p1: ^P1, p2: ^P2) {
	if p1.shape.x < 0 {
		p1.shape.x = 0
	} else if p1.shape.y > (f32(WIN_DIM.y) - p1.dim.y) {
		p1.shape.y = (f32(WIN_DIM.y) - p1.dim.y)
	} else if p1.shape.y < 0 {
		p1.shape.y = 0
	} else if p2.shape.x > (f32(WIN_DIM.x) - p2.dim.x) {
		p2.shape.x = (f32(WIN_DIM.x) - p2.dim.x)
	} else if p2.shape.y > (f32(WIN_DIM.y) - p2.dim.y) {
		p2.shape.y = (f32(WIN_DIM.y) - p2.dim.y)
	} else if p2.shape.y < 0 {
		p2.shape.y = 0
	}
}

// swapPlayers :: proc(p1: ^P1, p2: ^P2) {
// 	p1_original_position := p1^.shape
// 	p1.shape = p2.shape
// 	p2.shape = p1_original_position
// }

drawBall :: proc(ball: ^Ball) {
	rl.DrawCircle(i32(ball.pos.x), i32(ball.pos.y), ball.r, theme.ball)
}

drawP1 :: proc(p1: ^P1) {
	rl.DrawRectangleRounded(p1.shape, 0.7, 0, p1.col)
}

drawP2 :: proc(p2: ^P2) {
	rl.DrawRectangleRounded(p2.shape, 0.7, 0, p2.col)
}

moveBall :: proc(ball: ^Ball) {
	ball.pos += ball.vel * BALL_SPEED_MULT
}

collisionLogic :: proc(p1: ^P1, p2: ^P2, ball: ^Ball) {
	if ball.pos.y - ball.r < 0 {
		ball.pos.y = 0 + ball.r
		ball.vel.y = -ball.vel.y * DAMP_WALL
		rl.PlaySound(strike_fx2)
	} else if ball.pos.y + ball.r > f32(WIN_DIM.y) {
		ball.pos.y = (f32(WIN_DIM.y) - ball.r)
		ball.vel.y = -ball.vel.y * DAMP_WALL
		rl.PlaySound(strike_fx2)
	} else if rl.CheckCollisionCircleRec({ball.pos.x, ball.pos.y}, ball.r, p1.shape) &&
	   ball.vel.x < 0 {
		p1.hit = true
		if rl.IsKeyDown(rl.KeyboardKey.W) {
			ball.vel.x = -ball.vel.x * DAMP_SPIN
			ball.vel.y = -ball.vel.y * ACCEL_SPIN
			rl.PlaySound(strike_fx3)
		} else if rl.IsKeyDown(rl.KeyboardKey.S) {
			ball.vel.x = -ball.vel.x * DAMP_SPIN
			ball.vel.y = -ball.vel.y * ACCEL_SPIN
			rl.PlaySound(strike_fx3)
		} else {
			ball.vel.x = -ball.vel.x * BALL_SPEED_MULT
			rl.PlaySound(strike_fx1)
		}
	} else if rl.CheckCollisionCircleRec({ball.pos.x, ball.pos.y}, ball.r, p2.shape) &&
	   ball.vel.x > 0 {
		p2.hit = true
		if rl.IsKeyDown(rl.KeyboardKey.W) {
			ball.vel.x = -ball.vel.x * DAMP_SPIN
			ball.vel.y = -ball.vel.y * ACCEL_SPIN
			rl.PlaySound(strike_fx3)
		} else if rl.IsKeyDown(rl.KeyboardKey.S) {
			ball.vel.x = -ball.vel.x * DAMP_SPIN
			ball.vel.y = -ball.vel.y * ACCEL_SPIN
			rl.PlaySound(strike_fx3)
		} else {
			ball.vel.x = -ball.vel.x * BALL_SPEED_MULT
			rl.PlaySound(strike_fx1)
		}
	}

	if p1.hit == true {
		p1.col = ball.col
	} else if p2.hit == true {
		p2.col = ball.col
	} else {
		p1.col, p2.col = theme.p1, theme.p2
	}
}

scoreLogic :: proc(p1: ^P1, p2: ^P2, ball: ^Ball) {
	if ball.pos.x < 0 {
		scoreCounter += 1

		if scoreCounter > 60 {
			p2.scr += 1
			rl.PlaySound(score_fx2)
			ball.pos.x = f32(WIN_DIM.x / 2)
			ball.vel = m.float2{
				rnd.float32_normal(X_MEAN, X_SDEV),
				rnd.float32_normal(Y_MEAN, Y_SDEV),
			}
			scoreCounter = 0
		}
	} else if ball.pos.x > f32(WIN_DIM.x) {
		scoreCounter += 1

		if scoreCounter > 60 {
			p1.scr += 1
			rl.PlaySound(score_fx1)
			ball.pos.x = f32(WIN_DIM.x / 2)
			ball.vel = m.float2{
				rnd.float32_normal(-X_MEAN, X_SDEV),
				rnd.float32_normal(Y_MEAN, Y_SDEV),
			}
			scoreCounter = 0
		}
	}
}

drawEndScreen :: proc() {
	rl.DrawText("SQONG", 20, 20, 40, theme.txt_light)
	rl.DrawText(rl.TextFormat("%s", winner), 20, 80, 30, theme.txt_dark)
	rl.DrawText("To play again press ENTER", 20, 140, 20, theme.txt_dark)
	rl.DrawText("Press ESC to quit", 20, 200, 20, theme.txt_dark)
}

trackWinner :: proc(p1: ^P1, p2: ^P2) {
	if p1.scr > p2.scr {
		winner = "Player 1 Wins!"
	} else if p2.scr > p1.scr {
		winner = "Player 2 Wins!"
	} else {
		winner = "It's a draw!"
	}
}
