using DynamicPolynomials
using JuMP
using LinearAlgebra
import MathOptInterface as MOI
using SCS
using SumOfSquares
using Test

"""Load the required Julia stack and solve one minimal JuMP model with SCS."""
function run_jump_smoke()
    println("Julia version: ", VERSION)
    println("Active project: ", Base.active_project())
    for module_ref in (DynamicPolynomials, JuMP, MOI, SCS, SumOfSquares)
        println(nameof(module_ref), " version: ", Base.pkgversion(module_ref))
    end
    for package in ("Mosek", "MosekTools")
        path = Base.find_package(package)
        println(package, ": ", isnothing(path) ? "not available in active project" : path)
    end

    return @testset "JuMP and SCS smoke" begin
        model = Model(SCS.Optimizer)
        set_silent(model)
        @variable(model, x >= 1)
        @objective(model, Min, x)
        optimize!(model)

        @test termination_status(model) in (MOI.OPTIMAL, MOI.ALMOST_OPTIMAL)
        @test primal_status(model) == MOI.FEASIBLE_POINT
        @test isapprox(value(x), 1.0; atol=1e-4, rtol=0.0)
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    run_jump_smoke()
end
