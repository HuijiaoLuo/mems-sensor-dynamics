function dx = sensor_dynamics_model(t, xvec, k, r, u_fun)

    x = xvec(1);
    y = xvec(2);

    % External input
    u = u_fun(t);

    % State equations
    dxdt = y;
    dydt = u - k*x - r*y;

    dx = [dxdt; dydt];

end