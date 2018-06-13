function read_randomness_as_int(path="./noise.dat")
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
    # Between 1 and 10000. This doesn't add any additional quantum fun, but it
    # does ensure that pretty much every time you run the script it'll be
    # different. Even in this 'same' universe.
    # I guess.
    # Quantum mechanics is confusing.
    n = rand(1:10000) # the pseudorandom number
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

function build_workout_plan_as_dataframe()
    # stuff
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
    return(minimum([n_sprints, 20]))
end

function distance_to_400m_sprints(distance)
    # Wrapper to get 400m sprints. Pretty much as above.
    n_sprints = distance_to_sprints(distance, 400)
    return(minimum([n_sprints, 12]))
end

function distance_to_800m_sprints(distance)
    # Wrapper to get 800m with a cap. Again, as above.
    n_sprints = distance_to_sprints(distance, 800)
    return(minimum([n_sprints, 8]))
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

function main(total_weekly_distance, workouts_per_week, goal_distance=42.2)

    # Start by printing facts about current distance etc. to the console:
    println("Your Current Weekly Distance (km): ", total_weekly_distance)
    println("Your Current Weekly # of Workouts: ", workouts_per_week)
    println("Your Goal is to run ", goal_distance, " km in a single run.")

    # Build a raw array of daily workout distances:
    daily_distances = generate_raw_daily_kms(total_weekly_distance,
                                             workouts_per_week,
                                             goal_distance,
                                             1.025)

    # Get some sweet, sweet quantum noise from the file:
    noise = alter_noise_array(read_randomness_as_int())

    # Mix that quantum noise in with the daily distances:
    new_daily_distances = add_noise_to_distance_array(daily_distances, noise)

    # Shorten the daily distances in line with goal_distance:
    shortened_daily = slice_distance_array_to_goal(new_daily_distances,
                                                   goal_distance)

    println(shortened_daily)

end

# for i in 1:400
#     test = add_noise_to_workout_distance(5.0, b[i])
#     push!(workouts, test)
#     push!(multipliers, get_noise_multiplier(b[i]))
# end
# println(multipliers)

# open("/Users/galen/Desktop/random1e9.dat") do f
#     a = read(f)
#     b = reinterpret(Int8, a)
# end

# weekly_distances = calculate_distance_totals(50, 150, 1.05)
# println(weekly_distances)