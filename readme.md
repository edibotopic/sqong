# Sqong

v0.1.1

Pong-clone written in the [Odin language](http://odin-lang.org/) using the [Raylib](https://www.raylib.com/) game engine.
Made in a weekend to learn Odin and take a break from infuriating web projects.

To compile and run you will need to have Odin installed and on your path.
After you `git clone` this repo, change to the `/sqong/` directory and run `make`.

```bash
cd sqong
make
```

This will build a `sqong` executable in the `/bin/` directory.
On Linux, this can be run with `./bin/sqong`.

Note that the makefile invokes `odin` with a `-o:speed` flag,
to optimise for performance:

```odin
odin build . -o:speed -out:bin/sqong
```

If you want to develop with the code just run:

```odin
odin run . -out:bin/sqong
```

This will compile faster and also run the executable.

# Audio

Music and score FX are original compositions.

Collision FX were made by mouth.

You are free to reuse both.

# Scope

This is (currently) a bare bones implementation.

Your player is on the left, the CPU player is on the right.
The game is first to 4.

That's it.

# To-do

These things may never happen.

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

- v0.1.1: added makefile, updated instructions, added links
- v0.1.0: initial release
