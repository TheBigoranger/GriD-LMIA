range = 2:10;

%% xxxxxxxxxxxxx
record = zeros(length(range),1);
for i= 1:length(range)
    n = range(i);
    yalmip("clear");

    grid = linspace(0, 1, n);
    A = dpmat(grid, @(x) [-1, 0.5; -1, -2] ...
        + x * [-1.3, -20; 2, -10], Degree=1);
    B = dpmat(grid, @(x) [1, -4; -1, -1] ...
        + x * [2.2, 0.5; -6, -5], Degree=1);
    C = eye(2);
    D = zeros(2);

    P = dpvar(2, grid);
    diffP = rhodiff(P, [-1 1]);
    gamma = dpvar(1, grid, Degree=0);
    E1 = [diffP + P * A + A' * P, P * B, C';
        B' * P, -gamma * eye(2), D';
        C, D, -gamma * eye(2)] <= 0;
    E1 = applyPolya(E1,1);
    E2 = P >= 0;


    objective = gamma.LocalValues{1}{1};
    solver = 'lmilab';
    if exist('mosekopt', 'file') ~= 0
        solver = 'mosek';
    end
    opts = sdpsettings('solver', solver, 'verbose', 0);
    sol = optimize([E1.toYalmip, E2.toYalmip], objective, opts);
    record(i)=value(objective);
end
figure(1)
clf
plot(range,record);
hold on
%%
record_deg=zeros(length(range),1);
for i= 1:length(range)
    n = range(i);
    yalmip("clear");
    grid = linspace(0, 1, 2);
    A = dpmat(grid, @(x) [-1, 0.5; -1, -2] ...
        + x * [-1.3, -20; 2, -10], Degree=1);
    B = dpmat(grid, @(x) [1, -4; -1, -1] ...
        + x * [2.2, 0.5; -6, -5], Degree=1);
    C = eye(2);
    D = zeros(2);

    P = dpvar(2, grid, Degree=n);
    diffP = rhodiff(P, [-1 1]);
    gamma = dpvar(1, grid, Degree=0);
    % E1 = [diffP + P * A + A' * P, P * B, C';
    %     B' * P, -gamma * eye(2), D';
    %     C, D, -gamma * eye(2)]*BigI <= 0;
    E1 = [diffP + P * A + A' * P, P * B, C';
        B' * P, -gamma * eye(2), D';
        C, D, -gamma * eye(2)] <= 0;
    % E1 = E1.applyPolya(1);
    E2 = P >= 0;


    objective = gamma.LocalValues{1}{1};
    solver = 'lmilab';
    if exist('mosekopt', 'file') ~= 0
        solver = 'mosek';
    end
    opts = sdpsettings('solver', solver, 'verbose', 0);
    sol = optimize([E1.toYalmip, E2.toYalmip], objective, opts);
    record_deg(i)=value(objective);
end
figure(1)
plot(range,record_deg);

%% best ever
record_best=zeros(length(range),1);
for i= 1:length(range)
    n = range(i);
    yalmip("clear");
    grid = linspace(0, 1, n);
    A = dpmat(grid, @(x) [-1, 0.5; -1, -2] ...
        + x * [-1.3, -20; 2, -10], Degree=1);
    B = dpmat(grid, @(x) [1, -4; -1, -1] ...
        + x * [2.2, 0.5; -6, -5], Degree=1);
    C = eye(2);
    D = zeros(2);

    P = dpvar(2, grid, Degree=n);
    diffP = rhodiff(P, [-1 1]);
    gamma = dpvar(1, grid, Degree=0);
    % E1 = [diffP + P * A + A' * P, P * B, C';
    %     B' * P, -gamma * eye(2), D';
    %     C, D, -gamma * eye(2)]*BigI <= 0;
    E1 = [diffP + P * A + A' * P, P * B, C';
        B' * P, -gamma * eye(2), D';
        C, D, -gamma * eye(2)] <= 0;
    E1 = E1.applyPolya(1);
    E2 = P >= 0;


    objective = gamma.LocalValues{1}{1};
    solver = 'lmilab';
    if exist('mosekopt', 'file') ~= 0
        solver = 'mosek';
    end
    opts = sdpsettings('solver', solver, 'verbose', 0);
    sol = optimize([E1.toYalmip, E2.toYalmip], objective, opts);
    record_best(i)=value(objective);
end
figure(1)
plot(range,record_best);