function read_randomness_as_int(path="./random1e9.dat")
    open(path) do f
        raw_data = read(f)
        as_int8 = reinterpret(Int8, raw_data)
        return(as_int8)
    end
end

function get_noise_multiplier(noise::Int8)
    noise_multiplier = 1 + 0.25(noise/256)
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

function convert_distance_to_workout(workout_distance, noise::Int8)
    noise_multiplier = get_noise_multiplier(noise)
end

function build_daily_distance_array(workouts_per_week, distance_totals)
    # stuff

end

function build_workout_plan()
    # stuff
end



function main()
    a = read_randomness_as_int()
    println(a[2])
end




# total_weekly_distance = ARGS[1]
# workouts_per_week = ARGS[2]

# println("Total Weekly Distance (km): ", total_weekly_distance)
# println("Weekly Total # of Workouts: ", workouts_per_week)


# workouts = []
# multipliers = []
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