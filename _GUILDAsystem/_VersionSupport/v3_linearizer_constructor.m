function v3_linearizer_constructor(c_args)
% Reject the v3 constructor arguments of SolverLIN.
%
% v3 compatibility hook of the SolverLIN constructor. In v3,
% odeLinearizer(net, NonUnit, Algorithm=...) built a linearizer that held the network and
% its matrices (lin.get_sys, lin.odeLinearSystem); in v4 the solver holds defaults only
% (net.solver_LIN) and is created as SolverLIN(). Any argument stops with
% GUILDA:v3_linearizer_constructor:OdeLinearizerConstructor, which names net.get_sys.
%
% See also SolverLIN
    arguments (Input)
        c_args  % varargin of the constructor.
    end
    if ~isempty(c_args)
        error(msg("GUILDA:v3_linearizer_constructor:OdeLinearizerConstructor"));
    end
end
