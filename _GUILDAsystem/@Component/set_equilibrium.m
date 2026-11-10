function set_equilibrium(obj,c_V,c_I,r_P,r_Q,opt)
% Compute and store the state and input equilibria from the bus voltage and current.
%
% Called by Bus.set_equilibrium and initialize. With c_XU = {x, u} (the solution of
% initialize(Method="FixedInput")) the state and input equilibria are stored as given and
% get_equilibrium is not called. Clears the stale tag equilibrium. The
% local controllers compute their equilibria too and are then initialized with
% l_equilibrium = true (LocalController.initialize), which clears theirs. Stale handles
% are rebuilt first: a controller may design from them (local_LQR).
%
% <@Group> Called by analyses
    arguments (Input)
        obj 
        c_V   % [pu] Bus voltage phasor.
        c_I   % [pu] Current injected by the component.
        r_P = real( c_V*conj(c_I) );   % [pu] Active power injected by the component.
        r_Q = imag( c_V*conj(c_I) );   % [pu] Reactive power injected by the component.
        opt.c_XU (1,:) cell = {}        % {x, u}: the equilibrium to store as given; {} computes it with get_equilibrium.
    end
    obj.set_odefcn();
    if isempty(opt.c_XU)
        [cv_Xst,cv_Ust] = obj.get_equilibrium(c_V,c_I,r_P,r_Q);
    else
        cv_Xst = reshape(opt.c_XU{1}, [], 1);
        cv_Ust = reshape(opt.c_XU{2}, [], 1);
    end
    
    % c_V is the voltage of the bus (its owner); c_Vequilibrium reads it from there.
    obj.c_Iequilibrium  = c_I;
    obj.rv_Xequilibrium = cv_Xst;
    obj.rv_Uequilibrium = cv_Ust;

    obj.sct_stale.equilibrium = strings(0,1);

    % the controllers clear their own stale tag equilibrium (initialize(true))
    for k = 1:numel(obj.a_LocalController)
        obj.a_LocalController{k}.get_equilibrium(c_V, cv_Ust);
        obj.a_LocalController{k}.initialize(true);
    end
end
