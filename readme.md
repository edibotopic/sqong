# Sqong

v0.1.2

Pong-clone written in the [Odin language](http://odin-lang.org/) using the [Raylib](https://www.raylib.com/) programming library.
The game was made in a weekend to learn Odin and take a break from some infuriating web projects.

To compile and run you will need to have Odin [installed](https://odin-lang.org/docs/install/) and on your path.
After you `git clone` this repo, change to the `/sqong/` directory and run `make`.

```bash
cd sqong
make
```

This will build a `sqong` executable in the `/bin/` directory.
On Linux, this can then be run with `./bin/sqong`.

Note that the makefile invokes `odin` with a `-o:speed` flag
to optimise for performance:

```bash
odin build . -o:speed -out:bin/sqong
```

If you want to develop with the code just run:

```bash
odin run . -out:bin/sqong
```

This will compile faster and also run the executable.

# Audio

Theme music and score FX are original, quick compositions.

The collision FX consist of my own gently processed mouth sounds.

You are free to reuse both.

# Scope

This is (currently) a bare bones implementation.

A game is first to 4.

Your player is on the left, the CPU player is on the right.

That's it.

# To-do

## Priority

- [ ] Improve CPU/AI movement
- [ ] Less clunky title menu
- [ ] Continue refactoring code

## Nice-to-haves

- [ ] Allow window resize
- [ ] Menu with choices for theme/difficulty/audio
- [ ] Visible countdown before each serve
- [ ] Matches and games with side-switching
- [ ] Stress/stamina/aggression meter(s)
- [ ] Music adapts to game situation
- [ ] Game modes
- [ ] Better spin physics
- [ ] Additional strike styles (chip, arrow/straight, powershot)
- [ ] Pseudo-3D (ball scales close to net, casts a shadow)
- [ ] Context-dependent physics (grass level [no slide], ice level [slide], etc.)

# Changelog

- v0.1.2: added pause, started refactoring, updated readme
- v0.1.1: added makefile, updated instructions, added links
- v0.1.0: initial release
