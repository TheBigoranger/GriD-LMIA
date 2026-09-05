function verify_coeff(testCase, object, cellSubscript, expected)
    %VERIFY_COEFF Compare a complete physical-cell coefficient table.
    tests.infrastructure.verify_expr(testCase,object.coeffs(cellSubscript),expected);
end
