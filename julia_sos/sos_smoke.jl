using DynamicPolynomials
using JuMP
using LinearAlgebra
import MathOptInterface as MOI
using SCS
using SumOfSquares
using Test

"""Certify a minimal polynomial and inspect its numerical Gram evidence."""
function run_sos_smoke()
    return @testset "SumOfSquares smoke" begin
        @polyvar x
        polynomial_target = x^2 + 1
        model = SOSModel(SCS.Optimizer)
        set_silent(model)
        certificate = @constraint(model, polynomial_target >= 0)
        optimize!(model)

        @test termination_status(model) in (MOI.OPTIMAL, MOI.ALMOST_OPTIMAL)
        @test primal_status(model) == MOI.FEASIBLE_POINT

        gram = gram_matrix(certificate)
        gram_value = Matrix(gram.Q)
        reconstructed = polynomial(gram)
        mismatch = coefficients(reconstructed - polynomial_target)
        residual = isempty(mismatch) ? 0.0 : maximum(abs, mismatch)
        @test minimum(eigvals(Symmetric(gram_value))) >= -1e-5
        @test residual <= 1e-5
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    run_sos_smoke()
end
