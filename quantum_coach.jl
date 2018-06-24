#!/usr/bin/env julia
#
# Usage: julia -L quantum_coach.jl -e 'build_plan(weekly_kms, n_workouts_per_week, goal_distance)'
#
#    eg. 'build_plan(20, 4, 42.2)'
#          > This would output a taskpaper plan for someone who is currently
#            running ~20kms per week (spread across 4 workouts) and training for
#            a marathon distance run.


using DataFrames


function read_noise_as_int(path="./noise.dat")
    # Read binary quantum randomness from the noise.dat file and covert it into
    # an array of Int8 values for use.
    open(path) do f
        raw_data = read(f)
        as_int8 = reinterpret(Int8, raw_data)
        return(as_int8)
    end
end


function alter_noise_array(noise_array)
    # Assumes a long array of Int8 noise as input. Removes the first n values
    # from the front of the array, where 'n' is a pseudorandom positive integer
    # Between 10000 and 20000. This doesn't add any additional quantum fun, but
    # it does ensure that pretty much every time you run the script it'll be
    # different. Even in this 'same' universe.
    # I guess.
    # Quantum mechanics is confusing.
    n = 10000 + rand(1:10000) # the pseudorandom number
    new_noise = noise_array[n:length(noise_array)] # slice from n to the end
    return(new_noise)
end


function create_multiplier(noise::Int8)
    # Takes a single Int8 number and converts it into a 'noise_multiplier' for 
    # ease of use in varying workout distances.
    noise_multiplier = 1 + (noise/256)/4
    return(noise_multiplier)
end


function calculate_week_totals(current_total, max_total, rate)
    # Calculates each (weekly) distance total by multiplying the latest
    # distance by the increase 'rate' until the max distance is reached.

    distances = [max(1.0, current_total)] # ensures that growth is possible

    while distances[length(distances)] < max_total
        new_distance = distances[length(distances)] * rate
        push!(distances, new_distance)
    end

    return(distances)
end


function convert_to_daily(week_distance, runs_per_week)
    # tk
    daily_distance = week_distance / runs_per_week
    daily_workouts = fill(daily_distance, runs_per_week)
    return(daily_workouts)
end


function generate_daily_kms(current_km, n_runs, goal_km, rate)
    # Uses calculate_week_totals() and convert_to_daily() to make a raw array of
    # gradually increasing runs up to the goal distance.
    max_week_kms = goal_km * n_runs
    weeks = calculate_week_totals(current_km, max_week_kms, rate)
    day_distances = [convert_to_daily(x, n_runs) for x in weeks]
    flat_distances = collect(Iterators.flatten(day_distances))
    return(flat_distances)
end


function add_noise_to_distance_array(distances, noise)
    # Takes an array of distances and an array of 'noise' --- probably an array
    # of Int8 coming from read_noise_as_int() --- and adds noise to each
    # of the distances before returning a new array of noisy distances.
    noisy_distances = []
    for i in 1:length(distances)
        new_distance = distances[i] * create_multiplier(noise[i])
        push!(noisy_distances, new_distance)
    end
    return(noisy_distances)
end


function distance_to_sprints(distance_km, sprint_length_m)
    # Takes a distance number, rounds it, squashes it, and converts it to int of
    # n repeats of the specified sprint_length. Pretty ugly/stupid, but works.
    denom = sprint_length_m / 75 # so that longer sprints have fewer repeats
    n_sprints = ((distance_km*1000) / denom) / sprint_length_m
    return(Int(round(n_sprints)))
end


function distance_to_200m_sprints(distance)
    # Wrapper for distance_to_sprints, with a cap.
    n_sprints = distance_to_sprints(distance, 200)
    return(maximum([minimum([n_sprints, 20]),5]))
end


function distance_to_400m_sprints(distance)
    # Wrapper to get 400m sprints. Pretty much as above.
    n_sprints = distance_to_sprints(distance, 400)
    return(maximum([minimum([n_sprints, 12]),5]))
end


function distance_to_800m_sprints(distance)
    # Wrapper to get 800m with a cap. Again, as above.
    n_sprints = distance_to_sprints(distance, 800)
    return(maximum([minimum([n_sprints, 8]),4]))
end


function build_workout_dataframe(distances)
    # Wrapper to create a dataframe based on an array of raw distances.
    # Includes all major workout options.
    df = DataFrame(raw_distance = distances,
                   sprints_200m = [distance_to_200m_sprints(x) for x in distances],
                   sprints_400m = [distance_to_400m_sprints(x) for x in distances],
                   sprints_800m = [distance_to_800m_sprints(x) for x in distances],
                   fartlek = [round((0.55*x), 1) for x in distances],
                   hill_run = [round((0.35*x), 1) for x in distances],
                   long_run = [round((1*x), 1) for x in distances],
                   tempo = [round((0.7*x), 1) for x in distances])
    return(df)
end


function slice_distance_array_to_goal(distances, goal_distance)
    # Takes an array of workout distances and returns a new array, cutting
    # at the first time the goal distance is reached. This ensures that the
    # final training program won't get you to, say, a 42.2km and then have two
    # more weeks of 'training' after that.
    indexes = find(distances .< goal_distance)
    new_distances = vcat(distances[indexes], [goal_distance])
    return(new_distances)
end


function calculate_workout_distance(workout_type, workout_n)
    # Takes a workout type and associated number and returns the total distance
    # of the run. Used for calculating the workout's distance in reverse in the
    # case of sprints etc.
    if workout_type == "sprints_200m"
        distance = (workout_n*200)/1000
    elseif workout_type == "sprints_400m"
        distance = (workout_n*400)/1000
    elseif workout_type == "sprints_800m"
        distance = (workout_n*800)/1000
    else
        distance = workout_n
    end
    return(distance)
end


function daily_distance_is_safe(distances, workouts_per_week)
    # Takes an array of daily workout distances. Totals each week's distance,
    # and if any one week is more than 10% higher than the previous, returns
    # false. True otherwise.
    week_slice(x, n) = [x[i:min(i+n-1,length(x))] for i in 1:n:length(x)]
    weeks = week_slice(distances, workouts_per_week)
    println(weeks)
    week_totals = [sum(week) for week in weeks]
    println(week_totals)
    weekly_increase = []
    for i in 2:length(week_totals)
        push!(weekly_increase, week_totals[i]/week_totals[i-1])
    end
    return(weekly_increase)
end


function choose_workout_plan(workout_df, workouts_per_week)
    # Takes a workout_df, containing all the distances / options, along with
    # workouts_per_week. Reserves the final workout of each
    # week as a long run. Chooses at random between workouts for the remainder.
    # Painful sprints and hill runs are deliberately rare. 

    hard_w = ["hill_run",
              "sprints_200m",
              "sprints_400m",
              "sprints_800m",
              "sprints_800m"]

    easy_w = ["fartlek",
              "fartlek",
              "sprints_400m",
              "tempo",
              "tempo",
              "tempo"]

    plan_df = DataFrame(workout_type = String[],
                        workout_n = Float64[],
                        distance = Float64[])

    for i in 1:size(workout_df,1)

        if workout_df[i,:raw_distance] > 10
            # deliberately gotta be established for the hard things to have
            # a chance of occurring at all:
            workout_options = vcat(hard_w,repeat(easy_w,outer=2))
        elseif workout_df[i,:raw_distance] > 30
            workout_options = vcat(hard_w,easy_w)
        elseif workout_df[i,:raw_distance] > 40
            workout_options = vcat(easy_w,repeat(hard_w,outer=2))
        else
            workout_options = easy_w
        end

        # if it's the second to last workout, make it short sprints:
        if i == (length(workout_df[1])-1)
            workout = ["sprints_200m",
                       workout_df[i, :sprints_200m],
                       calculate_workout_distance("sprints_200m",
                                                  workout_df[i, :sprints_200m])]
            push!(plan_df, workout) # add the workout row to the plan_df
        # if it's the last run of the week or the program make it a long one:
        elseif i % workouts_per_week == 0 || i == length(workout_df[1])
            workout = ["long_run",
                       workout_df[i, :long_run],
                       workout_df[i, :long_run]]
            push!(plan_df, workout) # add the workout row to the plan_df
        # otherwise, normal options ...
        else
            n = rand(1:length(workout_options))
            chosen_workout = workout_options[n]
            workout_n = workout_df[i, Symbol(chosen_workout)]
            workout_distance = calculate_workout_distance(chosen_workout,
                                                          workout_n)
            workout = [chosen_workout,
                       workout_n,
                       workout_distance]
            push!(plan_df, workout) # add this messy workout to the plan_df
        end
    end
    return(plan_df)
end


function workout_to_taskpaper(run_type, run_n, run_distance)
    # Takes info about a workout; returns a taskpaper string representing it.
    # Designed for import to omnifocus. Pretty basic.
    run_time = Int(round(15 + run_distance*6.5)) # estimated task duration
    if contains(run_type, "sprints")
        sprint_length = run_type[search(run_type, r"[0-9]+m")]
        task = "Go for a run: $(Int(run_n)) repeats of $sprint_length"
    else
        workout_name = replace(run_type, "_", " ")
        if contains(run_type, "run")
            task = "Go for a $workout_name: $run_n km"
        else
            task = "Go for a $workout_name run: $run_n km"
        end
    end
    taskpaper_task = "- " * task * " @estimate($(run_time)m)"
    return(taskpaper_task)
end


function output_taskpaper(plan_df, n_workouts, add_recovery=true, add_defer=true)
    # Takes a workout plan dataframe and uses workout_to_taskpaper to output a
    # full list of workout tasks for import into omnifocus (or taskpaper!)

    run_plan = [workout_to_taskpaper(plan_df[i, :workout_type],
                                     plan_df[i, :workout_n],
                                     plan_df[i, :distance])
                for i in 1:size(plan_df, 1)]

    if add_recovery
        run_plan = add_recovery_workouts(run_plan, n_workouts)
    end

    if add_defer
        run_plan = add_defer_dates(run_plan, "today")
    end

    for i in 1:length(run_plan)
        println(run_plan[i])
    end

end


function add_defer_dates(tasklist, start_date)
    # Takes an array of strings (tasks) and adds taskpaper-formatted
    # 'start_date + [n]d' to each task before returning the array
    new_tasklist = []
    for i in 1:length(tasklist)
        new_task = "$(tasklist[i]) @defer($(start_date) +$(i)d)"
        push!(new_tasklist, new_task)
    end
    return(new_tasklist)
end


function choose_recovery_workout()
    # Returns a random workout in taskpaper format.
    workouts = ["- Do a kettlebell workout @estimate(30m)",
                "- Do the /r/bodyweightfitness Routine @estimate(60m)",
                "- Do a session of Yoga with Adriene @estimate(60m)"]
    return(workouts[rand(1:length(workouts))])
end


function pick_recovery_days(n_workouts)
    # Takes a number of workouts per week (int). Always returns an array of 
    # length 7 filled with bool values, representing a week where true == 'a
    # recovery day' and false == 'a running day'. Makes long run last day of
    # the week and assumes following day rest if possible
    if n_workouts >= 7
        return(fill(false, 7))
    else
        workouts_between = vcat(fill(false, (n_workouts-1)),
                                fill(true, (5-(n_workouts-1))))
        return(vcat(true, shuffle(workouts_between), false))
    end
end


function add_recovery_workouts(running_plan, n_workouts)
    # Takes an array of taskpaper workouts, along with the number of workouts in
    # each week. Fills all non-run days with taskpaper-formatted recovery tasks
    # and prioritises active recovery after the weekly long run.
    if n_workouts == 7
        full_schedule = running_plan
    else
        n_weeks = ceil(length(running_plan)/n_workouts)

        recovery_days = []

        for i in 1:n_weeks
            push!(recovery_days, pick_recovery_days(n_workouts))
        end

        recovery_days = collect(Iterators.flatten(recovery_days))

        full_schedule = []

        while length(running_plan) > 0
            if recovery_days[1] == true
                workout = choose_recovery_workout()
                push!(full_schedule, workout)
                deleteat!(recovery_days, 1)
            else
                workout = running_plan[1]
                push!(full_schedule, workout)
                deleteat!(recovery_days, 1)
                deleteat!(running_plan, 1)
            end
        end

    end
    
    return(full_schedule)

end


function build_plan(weekly_kms::Float64, n_workouts::Int64, goal_kms=42.2)

    # Build a raw array of daily workout distances:
    daily_kms = generate_daily_kms(weekly_kms,
                                   n_workouts,
                                   goal_kms,
                                   1.02)

    # Get some sweet, sweet quantum noise from the file:
    noise = alter_noise_array(read_noise_as_int())

    # Mix that quantum noise in with the daily distances:
    daily_kms = add_noise_to_distance_array(daily_kms, noise)

    # Shorten the daily distances in line with goal_kms:
    daily_kms = slice_distance_array_to_goal(daily_kms,
                                             goal_kms)

    # Build a workouts dataframe:
    workouts_df = build_workout_dataframe(daily_kms)

    # Build the final workouts plan:
    workout_plan = choose_workout_plan(workouts_df,
                                       n_workouts)

    # Print as taskpaper lines:
    println("Quantum Run Training Plan ($(goal_kms)km):")
    output_taskpaper(workout_plan, n_workouts)

end