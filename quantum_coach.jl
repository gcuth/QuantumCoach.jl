using DataFrames


function read_randomness_as_int(path="./noise.dat")
    # Read binary quantum randomness from the noise.dat file and covert it into
    # an array of Int8 values for use.
    open(path) do f
        raw_data = read(f)
        as_int8 = reinterpret(Int8, raw_data)
        return(as_int8)
    end
end


function normalise_int_to_range(n::Int8, new_min, new_max)
    # Takes an Int8 number; returns its normalised value (relative to -255:256)
    # within a new range. Used for getting a random number from the quantum
    # noise that's useable for cases similar to rand(0:n).
    a = (new_max - new_min) / (256 - (-255))
    b = new_min - (-255a)
    scaled_value = a * n + b
    return(Int(round(scaled_value)))
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


function get_noise_multiplier(noise::Int8)
    # Takes a single Int8 number and converts it into a 'noise_multiplier' for 
    # ease of use in varying workout distances.
    noise_multiplier = 1 + (noise/256)/4
    return(noise_multiplier)
end


function calculate_distance_totals(current_distance, max_distance, multiplier)
    # Calculates each (weekly) distance total by multiplying the latest
    # distance by the 'multiplier' until the max distance is reached.

    distances = [max(1.0, current_distance)] # ensures that growth is possible

    while distances[length(distances)] < max_distance
        new_distance = distances[length(distances)] * multiplier
        push!(distances, new_distance)
    end

    return(distances)
end


function add_noise_to_workout_distance(workout_distance, noise::Int8)
    noise_multiplier = get_noise_multiplier(noise)
    if noise > 0
        adjusted_distance = workout_distance * noise_multiplier
    elseif noise < 0
        adjusted_distance = workout_distance * noise_multiplier
    else
        adjusted_distance = workout_distance
    end
    return(adjusted_distance)
end


function convert_weekly_to_daily(distance, workouts_per_week)
    daily_distance = distance/workouts_per_week
    daily_workouts = fill(daily_distance, workouts_per_week)
    return(daily_workouts)
end


function generate_raw_daily_kms(current_weekly_distance,
                                current_workouts_per_week,
                                max_workout_distance,
                                multiplier)
    max_weekly_distance = max_workout_distance*current_workouts_per_week
    weekly_distances = calculate_distance_totals(current_weekly_distance,
                                                 max_weekly_distance,
                                                 multiplier)
    daily_distances = [convert_weekly_to_daily(x, current_workouts_per_week)
                       for x in weekly_distances]
    flat_daily_distances = collect(Iterators.flatten(daily_distances))
    return(flat_daily_distances)
end


function add_noise_to_distance_array(distances, noise)
    # Takes an array of distances and an array of 'noise' --- probably an array
    # of Int8 coming from read_randomness_as_int() --- and adds noise to each
    # of the distances before returning a new array of noisy distances.
    noisy_distances = []
    for i in 1:length(distances)
        new_distance = add_noise_to_workout_distance(distances[i], noise[i])
        push!(noisy_distances, new_distance)
    end
    return(noisy_distances)
end


function build_workout_dataframe_from_distances(distances)
    # Wrapper to create a dataframe based on an array of raw distances.
    # Includes all major workout options.
    df = DataFrame(raw_distance = distances,
                   sprints_200m = [distance_to_200m_sprints(x) for x in distances],
                   sprints_400m = [distance_to_400m_sprints(x) for x in distances],
                   sprints_800m = [distance_to_800m_sprints(x) for x in distances],
                   fartlek = [distance_to_fartlek(x) for x in distances],
                   hill_run = [distance_to_hill_climb(x) for x in distances],
                   long_run = [round((1.1*x), 1) for x in distances],
                   tempo = [round((0.9*x),1) for x in distances])
    return(df)
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


function distance_to_fartlek(distance)
    # Takes a distance and returns a smaller, rounded one for fartlek.
    return(round(distance*0.75, 1))
end


function distance_to_hill_climb(distance)
    # Takes a distance and returns a *much* smaller, rounded one for hills.
    return(round(distance*0.5, 1))
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


function choose_workout_plan(workout_df, workouts_per_week, noise)
    # Takes a workout_df, containing all the distances / options, along with
    # workouts_per_week and a noise array. Reserves the final workout of each
    # week as a long run. Chooses at random between workouts for the remainder.
    # Painful sprints and hill runs are deliberately rare. 

    hard_workouts = ["sprints_200m",
                     "hill_run",
                     "sprints_800m",
                     "sprints_800m"]

    easy_workouts = ["fartlek",
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
            workout_options = vcat(hard_workouts,repeat(easy_workouts,outer=2))
        else
            workout_options = easy_workouts
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
            noise_n = normalise_int_to_range(noise[i], 1, length(workout_options))
            chosen_workout = workout_options[noise_n]
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


function workout_to_taskpaper(workout_type, workout_n, workout_distance)
    # Takes info about a workout; returns a taskpaper string representing it.
    # Designed for import to omnifocus. Pretty basic.
    run_time = Int(round(15 + workout_distance*6.5)) # estimated task duration
    if contains(workout_type, "sprints")
        sprint_length = workout_type[search(workout_type, r"[0-9]+m")]
        task = "Go for a run: $(Int(workout_n)) repeats of $sprint_length"
    else
        workout_name = replace(workout_type, "_", " ")
        if contains(workout_type, "run")
            task = "Go for a $workout_name: $workout_n km"
        else
            task = "Go for a $workout_name run: $workout_n km"
        end
    end
    taskpaper_task = "- " * task * " @estimate($(run_time)m)"
    return(taskpaper_task)
end


function output_taskpaper(plan_df)
    # Takes a workout plan dataframe and uses workout_to_taskpaper to output a
    # full list of workout tasks for import into omnifocus (or taskpaper!)

    taskpaper_plan = [workout_to_taskpaper(plan_df[i, :workout_type],
                                           plan_df[i, :workout_n],
                                           plan_df[i, :distance])
                      for i in 1:size(plan_df, 1)]

    for i in 1:length(taskpaper_plan)
        println(taskpaper_plan[i])
    end

end


function main(total_weekly_distance::Float64,
              workouts_per_week::Int64,
              goal_distance=42.2)

    # Start by printing facts about current distance etc. to the console:
    println("Quantum Run Training Plan ($(goal_distance)km):")

    # Build a raw array of daily workout distances:
    daily_distances = generate_raw_daily_kms(total_weekly_distance,
                                             workouts_per_week,
                                             goal_distance,
                                             1.015)

    # Get some sweet, sweet quantum noise from the file:
    noise = alter_noise_array(read_randomness_as_int())

    # Mix that quantum noise in with the daily distances:
    new_daily_distances = add_noise_to_distance_array(daily_distances, noise)

    # Shorten the daily distances in line with goal_distance:
    shortened_daily = slice_distance_array_to_goal(new_daily_distances,
                                                   goal_distance)

    # Build a workouts dataframe:
    workouts = build_workout_dataframe_from_distances(shortened_daily)

    # Build the final workouts plan:
    workout_plan = choose_workout_plan(workouts,
                                       workouts_per_week,
                                       alter_noise_array(noise))

    # Print as taskpaper lines:
    output_taskpaper(workout_plan)

end