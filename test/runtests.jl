include("../src/coach.jl")

using Test

# @test length(read_noise()) > 0
# @test length(read_noise()) == 84671552

# @test length(alter_noise(read_noise())) > 0
# @test length(alter_noise(read_noise())) < 84671552

# @test create_multiplier(Int8(0)) == 1.0
# @test create_multiplier(Int8(127)) > 1.12
# @test create_multiplier(Int8(-127)) < 0.88

noise_array = alter_noise(read_noise())

workouts = generate_workout_sequence(8.0,
                          42.2,
                          noise_array,
                          4,
                          20,
                          200,
                          10,
                          200,
                          20,
                          600,
                          Dates.Date(2018,9,4),
                          true,
                          0.1,
                          Dates.Sunday)

for i in workouts
    println(i)
end