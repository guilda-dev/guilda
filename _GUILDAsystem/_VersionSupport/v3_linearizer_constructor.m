function v3_linearizer_constructor(c_args)
% Reject the v3 constructor arguments of LTIsolver.
%
% v3 compatibility hook of the LTIsolver constructor. In v3,
% odeLinearizer(net, NonUnit, Algorithm=...) built a linearizer that held the network and
% its matrices (lin.get_sys, lin.odeLinearSystem); in v4 the solver holds defaults only
% (net.solver_LIN) and is created as LTIsolver(). Any argument stops with
% GUILDA:Deprecated:OdeLinearizerConstructor, which names net.linearize and net.get_sys.
%
% Name-Value options:
%
% - `c_args` — varargin of the constructor.
%
% See also LTIsolver
    if ~isempty(c_args)
        error('GUILDA:Deprecated:OdeLinearizerConstructor', '%s', ...
              Deprecated("OdeLinearizerConstructor"));
    end
end
