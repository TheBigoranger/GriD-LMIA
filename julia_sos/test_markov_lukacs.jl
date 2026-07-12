using JuMP
using LinearAlgebra
import MathOptInterface as MOI
using SCS
using Test

include(joinpath(@__DIR__, "markov_lukacs.jl"))

function _solve_certificate(coeffs; basis=:bernstein, interval=(0.0, 1.0))
    model = Model(SCS.Optimizer)
    set_silent(model)
    certificate = add_markov_lukacs!(model, coeffs; basis=basis, interval=interval)
    optimize!(model)
    return model, certificate
end

function _check_numerical_evidence(certificate)
    reconstructed = value.(certificate.represented_coefficients)
    residual = maximum(abs.(reconstructed .- certificate.normalized_coefficients))
    minimum_eigenvalue = minimum(
        minimum(eigvals(Symmetric(value.(gram)))) for gram in certificate.grams
    )
    @test residual <= 1e-5
    @test minimum_eigenvalue >= -1e-5
end

"""Exercise even/odd Markov-Lukacs forms, both bases, and invalid inputs."""
function run_markov_lukacs_tests()
    return @testset "Markov-Lukacs certificates" begin
        @testset "even Bernstein polynomial beyond coefficient positivity" begin
            model, certificate = _solve_certificate([0.35, -0.15, 0.35])
            @test certificate.degree == 2
            @test certificate.parity == :even
            @test termination_status(model) in (MOI.OPTIMAL, MOI.ALMOST_OPTIMAL)
            _check_numerical_evidence(certificate)
        end

        @testset "odd physical power polynomial on a non-unit interval" begin
            # (rho + 1)^3 + 0.1 is strictly positive on [-1, 2].
            model, certificate = _solve_certificate(
                [1.1, 3.0, 3.0, 1.0]; basis=:power, interval=(-1.0, 2.0)
            )
            @test certificate.degree == 3
            @test certificate.parity == :odd
            @test termination_status(model) in (MOI.OPTIMAL, MOI.ALMOST_OPTIMAL)
            _check_numerical_evidence(certificate)
        end

        @testset "degree-zero and boundary-zero cases" begin
            constant_model, constant_certificate = _solve_certificate([2.0])
            @test length(constant_certificate.grams) == 1
            @test termination_status(constant_model) in (MOI.OPTIMAL, MOI.ALMOST_OPTIMAL)
            _check_numerical_evidence(constant_certificate)

            boundary_model, boundary_certificate = _solve_certificate([0.0, 0.5, 0.0])
            @test termination_status(boundary_model) in (MOI.OPTIMAL, MOI.ALMOST_OPTIMAL)
            _check_numerical_evidence(boundary_certificate)
        end

        @testset "Bernstein and physical-power inputs agree" begin
            interval = (2.0, 5.0)
            bernstein_model = Model(SCS.Optimizer)
            power_model = Model(SCS.Optimizer)
            bernstein_certificate = add_markov_lukacs!(
                bernstein_model, [0.35, -0.15, 0.35]; interval=interval
            )
            power_coeffs = [4 / 9 + 2 / 3 + 0.35, -7 / 9, 1 / 9]
            power_certificate = add_markov_lukacs!(
                power_model, power_coeffs; basis=:power, interval=interval
            )
            @test bernstein_certificate.normalized_coefficients ≈
                power_certificate.normalized_coefficients atol = 1e-12
        end

        @testset "negative and invalid inputs" begin
            model, _ = _solve_certificate([-1.0])
            @test termination_status(model) in (MOI.INFEASIBLE, MOI.ALMOST_INFEASIBLE)

            blank_model = Model(SCS.Optimizer)
            @test_throws ArgumentError add_markov_lukacs!(blank_model, Float64[])
            @test_throws ArgumentError add_markov_lukacs!(blank_model, [1.0, Inf])
            @test_throws ArgumentError add_markov_lukacs!(blank_model, [1.0]; basis=:chebyshev)
            @test_throws ArgumentError add_markov_lukacs!(blank_model, [1.0]; interval=(1.0, 1.0))
            @test_throws ArgumentError add_markov_lukacs!(blank_model, [1.0]; interval=(0.0, Inf))
            @test_throws ArgumentError add_markov_lukacs!(blank_model, [1.0 2.0])
            @test_throws ArgumentError add_markov_lukacs!(blank_model, ComplexF64[1 + 0im])
        end
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    run_markov_lukacs_tests()
end
