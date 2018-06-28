using PowerSystems
using Base.Test
using CSV
using DataFrames

# Testing Topological components of the schema


tic()
println("Read Data in *.jl files")
@time @test include("readnetworkdata.jl")
println("Test all the constructors")
@time @test include("constructors.jl")
println("Test PowerSystem constructor")
@test include("powersystemconstructors.jl")

#println("Testing Network Matrices")
#@time @test include("network_matrices.jl")
println("Read Parsing code")
@time @test include("parsestandard.jl")

println("Reading forecast data ")
@time @test include("readforecastdata.jl")
include("../data/data_5bus.jl");

@assert "$sys5" == "PowerSystems.PowerSystem(buses=5, branches=6)"

toc()
