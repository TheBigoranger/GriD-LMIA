using JuMP

"""
    add_markov_lukacs!(model, coeffs; basis=:bernstein, interval=(0.0, 1.0))

Add a scalar Markov-Lukacs certificate for a polynomial on a finite interval.
Bernstein coefficients follow DP-LMI label order from the lower to the upper
endpoint. Power coefficients are ordered by ascending powers of the physical
variable. The returned named tuple exposes the normalized polynomial, Gram
matrices, and coefficient-matching constraints for independent diagnostics.
"""
function add_markov_lukacs!(
    model::JuMP.Model,
    coeffs;
    basis=:bernstein,
    interval=(0.0, 1.0),
)
    a, b = _check_interval(interval)
    c = _check_coeffs(coeffs)
    basis in (:bernstein, :power) ||
        throw(ArgumentError("basis must be :bernstein or :power"))

    # Work in the forward local coordinate t=(rho-a)/(b-a). This preserves the
    # repository's endpoint label order while keeping the interval weights simple.
    local_c = basis === :bernstein ? _bernstein_to_power(c) : _power_to_local(c, a, b)
    while length(local_c) > 1 && iszero(last(local_c))
        pop!(local_c)
    end

    degree = length(local_c) - 1
    parity = iseven(degree) ? :even : :odd
    represented, grams = parity === :even ?
        _add_even_certificate!(model, degree) :
        _add_odd_certificate!(model, degree)
    constraints = [@constraint(model, represented[k] == local_c[k]) for k in eachindex(local_c)]

    return (
        normalized_coefficients=local_c,
        degree=degree,
        parity=parity,
        grams=grams,
        represented_coefficients=represented,
        coefficient_constraints=constraints,
    )
end

function _check_interval(interval)
    (interval isa Tuple && length(interval) == 2) ||
        throw(ArgumentError("interval must be a two-element tuple"))
    a, b = interval
    (a isa Real && b isa Real && isfinite(a) && isfinite(b) && a < b) ||
        throw(ArgumentError("interval endpoints must be finite reals with a < b"))
    return float(a), float(b)
end

function _check_coeffs(coeffs)
    coeffs isa AbstractVector || throw(ArgumentError("coeffs must be a nonempty real vector"))
    isempty(coeffs) && throw(ArgumentError("coeffs must be nonempty"))
    all(x -> x isa Real && isfinite(x), coeffs) ||
        throw(ArgumentError("coeffs must contain only finite real values"))
    return collect(float.(coeffs))
end

function _bernstein_to_power(coeffs)
    degree = length(coeffs) - 1
    power = zeros(promote_type(eltype(coeffs), Float64), degree + 1)
    for i in 0:degree
        scale = coeffs[i + 1] * binomial(degree, i)
        for j in 0:(degree - i)
            power[i + j + 1] += scale * binomial(degree - i, j) * (-1)^j
        end
    end
    return power
end

function _power_to_local(coeffs, a, b)
    degree = length(coeffs) - 1
    width = b - a
    local_c = zeros(promote_type(eltype(coeffs), typeof(a), Float64), degree + 1)
    for i in 0:degree
        for k in 0:i
            local_c[k + 1] += coeffs[i + 1] * binomial(i, k) * a^(i - k) * width^k
        end
    end
    return local_c
end

function _gram_coefficients(gram)
    size(gram, 1) == size(gram, 2) || error("internal Gram matrix must be square")
    degree = 2 * (size(gram, 1) - 1)
    coeffs = [AffExpr(0.0) for _ in 0:degree]
    for i in axes(gram, 1), j in axes(gram, 2)
        coeffs[i + j - 1] += gram[i, j]
    end
    return coeffs
end

function _add_even_certificate!(model, degree)
    n = degree ÷ 2
    q0 = @variable(model, [1:(n + 1), 1:(n + 1)], PSD)
    represented = _gram_coefficients(q0)
    n == 0 && return represented, (q0,)

    q1 = @variable(model, [1:n, 1:n], PSD)
    interior = _gram_coefficients(q1)
    for k in eachindex(interior)
        represented[k + 1] += interior[k]
        represented[k + 2] -= interior[k]
    end
    return represented, (q0, q1)
end

function _add_odd_certificate!(model, degree)
    n = (degree - 1) ÷ 2
    q0 = @variable(model, [1:(n + 1), 1:(n + 1)], PSD)
    q1 = @variable(model, [1:(n + 1), 1:(n + 1)], PSD)
    left = _gram_coefficients(q0)
    right = _gram_coefficients(q1)
    represented = [AffExpr(0.0) for _ in 0:degree]

    for k in eachindex(left)
        represented[k + 1] += left[k]
        represented[k] += right[k]
        represented[k + 1] -= right[k]
    end
    return represented, (q0, q1)
end
