using Test

include(joinpath(@__DIR__, "jump_smoke.jl"))
include(joinpath(@__DIR__, "sos_smoke.jl"))
include(joinpath(@__DIR__, "test_markov_lukacs.jl"))

@testset "Julia SOS comparison baseline" begin
    run_jump_smoke()
    run_sos_smoke()
    run_markov_lukacs_tests()
end
