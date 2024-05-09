function set_simulated_time(app,t)
    if nargin==2
        app.simulate_time(1) = t(1);
        app.simulate_time(2) = t(2);
    end
    app.simulate_time_start.Value = num2str(app.simulate_time(1));
    app.simulate_time_end.Value   = num2str(app.simulate_time(2));
end