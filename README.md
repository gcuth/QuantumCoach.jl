# QuantumCoach.jl

If you've ever wanted to train for a marathon in a way that's extremely inefficient yet specific to this universe (and *only* this universe!), then `QuantumCoach.jl` is the tool for you.

It's a [Julia](https://julialang.org/) script that uses data generated by a [Quantis brand quantum device](https://www.idquantique.com/resource-library/random-number-generation/) --- along with information about your current total weekly distance and workout frequency --- to generate a daily training program that will gradually increase your total weekly distance until you find yourself running 42.2 kilometers in a single day. It outputs in Omnifocus-compatible taskpaper, and (optionally) includes a selection of random non-running workouts for the recovery-days.

The data from the [Quantis brand quantum device](https://www.idquantique.com/resource-library/random-number-generation/) is generated by shooting photons at a partially-silvered mirror, **which is what makes this all special (and strange)**. Sure, you'll run in every universe, but thanks to a Swiss-made Quantum Random Number Generator, you'll run slightly differently in each. Provided you agree with [the many-worlds interpretation](https://en.m.wikipedia.org/wiki/Many-worlds_interpretation) of quantum mechanics, I suppose.

## Getting Started
You'll need three things to use this script:
- [Julia](https://julialang.org/)
- A huge `.dat` file of quantum noise (I'm using the free sample taken from the [ID Quantique website](https://www.idquantique.com/resource-library/random-number-generation/))
- Information about your current running activity and goal distance.

### Example Usage
The easiest way to use this is to load `coach.jl` and then eval `build_plan()` with your personal workout details, in the form:

```julia
build_plan(total_weekly_distance_in_km, number_of_running_workouts_per_week, goal_distance)
```

For example, if I were running four times a week for a total of 30.0km and was aiming for a marathon distance:

```bash
$ julia -L coach.jl -e 'build_plan(30.0, 4, 42.2)'
```

This will output a taskpaper project, looking something like this:

```
Quantum Run Training Plan (42.2km):
- Do a session of Yoga with Adriene @estimate(60m) @defer(today +1d)
- Do the /r/bodyweightfitness Routine @estimate(60m) @defer(today +2d)
- Go for a fartlek run: 4.4 km @estimate(44m) @defer(today +3d)
- Go for a tempo run: 4.9 km @estimate(47m) @defer(today +4d)
- Do a session of Yoga with Adriene @estimate(60m) @defer(today +5d)
- Go for a fartlek run: 3.7 km @estimate(39m) @defer(today +6d)
- Go for a long run: 8.1 km @estimate(68m) @defer(today +7d)
[...]
- Do the /r/bodyweightfitness Routine @estimate(60m) @defer(today +610d)
- Go for a long run: 42.2 km @estimate(289m) @defer(today +611d)
```

It's pretty basic in a lot of ways, but it's unique to this universe.

### Warnings
You probably shouldn't use `QuantumCoach.jl` if you:
- Are very new to running (try [c25k](http://www.c25k.com/)), or
- Want to be training in an efficient or sensible way.

Also, while this is probably obvious:
- The whole 'unique to this universe' schtick only works if you fully commit to following the training program, and
- I'm not responsible if you hurt yourself while following the training program.

## Motivation
I've written a bit about the motivation for this project, and logic of the script, on [my blog](https://zgcuth.me/quantum-run). Broadly speaking though, the dumb motivation behind `QuantumCoach.jl` is obvious: every time I run, my life diverges from the other, many worlds.

I'll never know what it's like to train for a marathon in Universe B, but I feel a connection with that Other Self. Thanks to the behaviour of photons, we suffer differently. Together.

It blows my mind that I can achieve this with a few lines of code (in a language I barely understand) and a concrete commitment to following the generated project. I use [beeminder](https://www.beeminder.com/) to increase the chances that I'll run as required, but honestly, I rarely need it. Thanks to some deep brokenness / cognitive bias, the solidarity is enough. Every time I drag my feet and think about skipping a workout, I think about all my other world selves. I pull on my runners so as not to let them down.

## Licence
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.