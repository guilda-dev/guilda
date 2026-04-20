function sys = get_sys(obj)
    lin = odeLinearizer(obj, 7, "Algorithm", "Feedbac");
    sys = lin.get_sys;
end