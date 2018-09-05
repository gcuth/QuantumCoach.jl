import Random
import Dates
import Statistics

function read_noise(path="../noise.dat")
    # Read binary quantum randomness from noise.dat; return it as an Int8 array.
    open(path) do f
        raw_data = read(f)
        as_int8 = reinterpret(Int8, raw_data)
        return(as_int8)
    end
end

function alter_noise(raw_noise)
    # Take an array of Int8 noise, slice off a bit of it, and return it.
    n = 10000 + rand(1:10000) # the pseudorandom number
    new_noise = raw_noise[n:length(raw_noise)-n] # slice from n to the end
    return(new_noise)
end

function create_multiplier(noise::Int8)::Float64
    # Take an Int8 number; convert it into a 'noise_multiplier' for ease of use.
    noise_multiplier = 1 + (noise/256)/4
    return(noise_multiplier)
end

function add_defer_date(workout::String, date::Dates.Date)::String
    workout = "$(workout) @defer($(date) 5am)"
    return(workout)
end

function add_due_date(workout::String, date::Dates.Date)::String
    workout = "$(workout) @due($(date) 5pm)"
    return(workout)
end

function distance_to_sprints(distance_km, sprint_length_m)
    # Takes a distance number, rounds it, squashes it, and converts it to int of
    # n repeats of the specified sprint_length. Pretty ugly/stupid, but works.
    denom = sprint_length_m / 75 # so that longer sprints have fewer repeats
    n_sprints = ((distance_km*1000) / denom) / sprint_length_m
    return(Int(round(n_sprints)))
end

function distance_to_200m(distance)
    # Wrapper for distance_to_sprints, with a cap, for 200m sprints.
    n_sprints = distance_to_sprints(distance, 200)
    return(maximum([minimum([n_sprints, 20]),5]))
end

function distance_to_400m(distance)
    # Wrapper to get n of 400m sprints. Pretty much as above.
    n_sprints = distance_to_sprints(distance, 400)
    return(maximum([minimum([n_sprints, 12]),5]))
end

function distance_to_800m(distance)
    # Wrapper to get 800m sprint n with a cap. Again, as above.
    n_sprints = distance_to_sprints(distance, 800)
    return(maximum([minimum([n_sprints, 8]),4]))
end

function get_run_workout_options(distance::Float64)
    # Takes a workout distance and returns an array of workout options. The
    # proportion of hard vs easy workouts changes as the distance increases.
    hard_w = ["hill_run",
              "sprints_200m",
              "sprints_400m",
              "sprints_800m"]
    easy_w = ["fartlek",
              "tempo"]

    if distance < 15
        options = easy_w
    else
        options = vcat(repeat(easy_w, outer=5),
                       repeat(hard_w, outer=Int(div(distance,10))))
    end

    return(options)
end

function choose_a_run_workout_type(distance::Float64)
    # Take distance, generate the options list, and then choose a workout type.
    options = get_run_workout_options(distance)
    return(options[rand(1:length(options))])
end

function add_estimate(workout::String, distance::Float64)::String
    # Take a workout and its distance and return workout with estimate added.
    workout = "$(workout) @estimate($(10 + Int(round(distance))*6)m)"
    return(workout)
end

function build_run_workout(distance::Float64, kind::String)::String
    # Take distance and workout kind and return full task (with estimate).
    if kind == "sprints_200m"
        workout = "- Go for a run: $(distance_to_200m(distance)) repeats of 200m"
    elseif kind == "sprints_400m"
        workout = "- Go for a run: $(distance_to_400m(distance)) repeats of 400m"
    elseif kind == "sprints_800m"
        workout = "- Go for a run: $(distance_to_800m(distance)) repeats of 800m"
    elseif kind == "tempo"
        workout = "- Go for a tempo run: $(minimum([round((0.7*distance); digits = 1), 20.0])) km"
    elseif kind == "fartlek"
        workout = "- Go for a fartlek run: $(minimum([round((0.55*distance); digits = 1), 20.0])) km"
    elseif kind == "hill_run"
        workout = "- Go for a hill run: $(minimum([round((0.35*distance); digits = 1), 15.0])) km"
    elseif kind == "long_run"
        workout = "- Go for a long run: $(round(distance; digits = 1)) km"
    else
        workout = "- Go for a run"
    end

    return(workout)
end



function build_cross_workout()::String
    options = ["Do a kettlebell workout @estimate(90m)",
               "Do the /r/bodyweightfitness routine @estimate(90m)"]
    workout = "- $(options[rand(1:length(options))])"
    return(workout)
end

function is_run_workout(workout::String)::Bool
    # Takes a workout string and returns whether or not it's a run workout.
    return(occursin("run: ", workout) && occursin("- Go for a ", workout))
end

function is_bodyweight_workout(workout::String)::Bool
    return(occursin("/r/bodyweightfitness routine", workout))
end

function is_kettlebell_workout(workout::String)::Bool
    return(occursin("kettlebell workout", workout))
end


function expand_run_workout(workout::String, pushups::Int64, pullups::Int64)::String
    short_workout = replace(workout, r"@(defer|due).+" => "")

    expanded_workout = "$(workout) @autodone(true) @parallel(false)\n"
    expanded_workout = "$(expanded_workout)    $(short_workout)\n"

    pushups_sets = div(pushups, 25)
    pullups_sets = div(pullups, 10)
    n_sets = maximum([minimum([pushups_sets, pullups_sets]), 1])

    pushups_options = ["wide","diamond","regular"]

    for i in 1:n_sets
        expanded_workout = "$(expanded_workout)    - Do 25 $(pushups_options[rand(1:length(pushups_options))]) pushups @estimate(5m)\n"
        expanded_workout = "$(expanded_workout)    - Do 10 pullups @estimate(5m)\n"
    end

    expanded_workout = "$(expanded_workout)    - Stretch to touch toes for 100 seconds @estimate(2m)\n"
    expanded_workout = "$(expanded_workout)    - Log $(n_sets*25) total pushups to exist.io @estimate(5m)\n"
    expanded_workout = "$(expanded_workout)    - Log $(n_sets*10) total pullups to exist.io @estimate(5m)"

    return(expanded_workout)
end

function get_descending_reps_sets(n_max::Int64)
    all_sets = [1]
    while sum(all_sets) <= n_max
        push!(all_sets, all_sets[length(all_sets)] + 1)
    end

    return(reverse(all_sets))
end

function expand_kettlebell_workout(workout::String, pushups::Int64, pullups::Int64, kettlebells::Int64)::String
    expanded_workout = "$(workout) @autodone(true) @parallel(false)\n"
    sets = [get_descending_reps_sets(x) for x in [Int64(pushups), Int64(pullups), Int64(round(kettlebells/20))]]
    min_set = sets[findmin([length(x) for x in sets])[2]]
    
    for i in min_set
        expanded_workout = "$(expanded_workout)    - Do $(i*10) kettlebell goblet squats @estimate(5m)\n    - Do $(i) pullups @estimate(5m)\n    - Do $(i*10) kettlebell swings @estimate(5m)\n    - Do $(i) pushups @estimate(5m)\n"
    end

    expanded_workout = "$(expanded_workout)    - Log $(sum(min_set)*10) total kettlebell goblet squats to exist.io @estimate(5m)\n"
    expanded_workout = "$(expanded_workout)    - Log $(sum(min_set)*10) total kettlebell swings to exist.io @estimate(5m)\n"
    expanded_workout = "$(expanded_workout)    - Log $(sum(min_set)) total pullups to exist.io @estimate(5m)\n"
    expanded_workout = "$(expanded_workout)    - Log $(sum(min_set)) total pushups to exist.io @estimate(5m)"

    return(expanded_workout)

end

function expand_bodyweight_workout(workout::String)::String
    expanded_workout = "$(workout) @autodone(true) @parallel(false)\n    - Do 10 resistance band shoulder dislocates @estimate(5m)\n    - Do 10 resistance band chest flies @estimate(5m)\n    - Do 10 resistance band lateral raises @estimate(5m)\n    - Do 10 resistance band front raises @estimate(5m)\n    - Do 10 squat sky reaches @estimate(5m)\n    - Do 10+ wrist warm-up stretches @estimate(5m)\n    - Do 10 cat-camels @estimate(5m)\n    - Do 10 shoulder shrugs @estimate(5m)\n    - Do 60 second front plank @estimate(5m)\n    - Do 60 second left-side plank @estimate(5m)\n    - Do 60 second right-side plank @estimate(5m)\n    - Do 60 second reverse plank @estimate(5m)\n    - Do 60 second hollow hold @estimate(5m)\n    - Do 60 second arch hold @estimate(5m)\n    - Do 5 pull-ups @estimate(5m)\n    - Do 5 dips @estimate(5m)\n    - Do 5 pull-ups @estimate(5m)\n    - Do 5 dips @estimate(5m)\n    - Do 5 pull-ups @estimate(5m)\n    - Do 5 dips @estimate(5m)\n    - Do 30 second L-Sit @estimate(5m)\n    - Do 5 squats @estimate(5m)\n    - Do 30 second L-Sit @estimate(5m)\n    - Do 5 squats @estimate(5m)\n    - Do 30 second L-Sit @estimate(5m)\n    - Do 5 squats @estimate(5m)\n    - Do 5 push-ups @estimate(5m)\n    - Do 5 rows @estimate(5m)\n    - Do 5 push-ups @estimate(5m)\n    - Do 5 rows @estimate(5m)\n    - Do 5 push-ups @estimate(5m)\n    - Do 5 rows @estimate(5m)\n    - Do hip-flexors mobility stretches @estimate(5m)\n    - Hold pigeon-pose for 60 seconds each side @estimate(5m)\n    - Stretch to touch toes for 100 seconds @estimate(5m)\n    - Log 15 total pull-ups to exist.io @estimate(5m)\n    - Log 15 total push-ups to exist.io @estimate(5m)"
    return(expanded_workout)
end

function expand_cross_workout(workout::String, pushups::Int64, pullups::Int64, kettlebells::Int64)::String
    if is_kettlebell_workout(workout)
        expanded_workout = expand_kettlebell_workout(workout, pushups, pullups, kettlebells)
    elseif is_bodyweight_workout(workout)
        expanded_workout = expand_bodyweight_workout(workout)
    else
        expanded_workout = workout
    end
    return(expanded_workout)
end

function detect_distance(workout::String)::Float64
    # Take a raw workout string (possibly expanded) and return estimate distance
    headline = string(match(r"^.+", workout).match)
    estimate = string(match(r"@estimate\([0-9]+m\)", headline).match)
    
    if occursin("repeats of", headline)
        return(parse(Float64, string(match(r"[0-9]+", estimate).match)) / 6)
    elseif is_run_workout(headline)
        distance = match(r"[0-9]+\.[0-9]+ km", headline).match
        return(parse(Float64, distance[1:end-3]))
    else
        return(parse(Float64, string(match(r"[0-9]+", estimate).match)) / 12)
    end
end


function generate_workout(raw_distance::Float64,
                          noise_multiplier::Float64,
                          n_runs_per_week::Int64,
                          push_up_max::Int64,
                          pull_up_max::Int64,
                          kettlebell_max::Int64,
                          current_day::Dates.Date,
                          expand_task = true,
                          bias = 0.01,
                          rest_day = Dates.Sunday,
                          must_run = false)
    
    distance = raw_distance * (noise_multiplier + bias)

    if Dates.dayofweek(current_day + Dates.Day(1)) == rest_day
        workout = build_run_workout(distance, "long_run")
        workout = add_estimate(workout, distance)
    elseif Dates.dayofweek(current_day) == rest_day
        workout = "- Do a session of yoga with Adriene @estimate(90m)"
    else
        if rand(1:5) <= n_runs_per_week-1 || must_run
            workout = build_run_workout(distance,
                                        choose_a_run_workout_type(distance))
            workout = add_estimate(workout, distance)
        else
            workout = build_cross_workout()
        end
    end

    workout = add_defer_date(workout, current_day)
    workout = add_due_date(workout, current_day)

    if expand_task
        if is_run_workout(workout)
            workout = expand_run_workout(workout,
                                         push_up_max,
                                         pull_up_max)
        else
            workout = expand_cross_workout(workout,
                                           push_up_max,
                                           pull_up_max,
                                           kettlebell_max)
        end
    end

    return(workout)
end


function generate_workout_sequence(last_run_distance::Float64,
                                   goal_run_distance::Float64,
                                   raw_noise_array,
                                   n_runs_per_week::Int64,
                                   current_pushups::Int64,
                                   pushups_max::Int64,
                                   current_pullups::Int64,
                                   pullups_max::Int64,
                                   current_kettlebells::Int64,
                                   kettlebells_max::Int64,
                                   program_start_date::Dates.Date,
                                   expand_task = true,
                                   bias = 0.05,
                                   rest_day = Dates.Sunday)
    pushups = current_pushups
    pullups = current_pullups
    kettlebells = current_kettlebells
    workouts = []
    days_since_last_run = 0
    workout_distances = [last_run_distance]
    workout_date = program_start_date

    while workout_distances[length(workout_distances)] < goal_run_distance

        target_distance = Statistics.mean([5 + length(workouts)/21,
                                           5 + length(workouts)/14,
                                           Statistics.mean(workout_distances),
                                           Statisitics.median(workout_distances)])

        workout = generate_workout(target_distance,
                                   create_multiplier(pop!(raw_noise_array)),
                                   n_runs_per_week,
                                   pushups,
                                   pullups,
                                   kettlebells,
                                   workout_date,
                                   expand_task,
                                   bias,
                                   rest_day,
                                   days_since_last_run > 5)

        if pushups < pushups_max
            pushups += rand(0:1)
        end

        if pullups < pullups_max && Dates.dayofweek(workout_date) == rest_day
            pullups += 1
        end

        if kettlebells < kettlebells_max
            kettlebells += 5
        end

        push!(workouts, workout)

        if is_run_workout(workout)
            append!(workout_distances, detect_distance(workout))
            days_since_last_run = 0
        else
            days_since_last_run += 1
        end

        workout_date = workout_date + Dates.Day(1)
    end
    return(workouts)
end
