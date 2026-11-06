classdef (Sealed = true) NewtonRaphsonMethod < auxiliary
% Newton-Raphson solver of a nonlinear equation F(x) = b.
%
% The continuation power flow uses it as its corrector. Give the equation and the options
% as Name-Value arguments of the constructor (they are the public properties), then call
% solve. Without NRMJac the Jacobian is computed by central differences with step
% Increment; giving NRMJac is usually faster. NRMFcn may be a symbolic expression (needs
% Symbolic Math Toolbox); GUILDA itself always passes function handles.
%
% <@Examples>
% ```matlab
% nrm = NewtonRaphsonMethod(NRMFcn=@(x) [x(1)^2 + x(2); x(2)^3], ...
%                           NRMVal=[2; 1], InitVal=[0.5; 0.5]);
% [x, n_iter] = nrm.solve();
% ```
%
% See also SolverCPF
    
    properties (Access=public) % Equation
        NRMFcn                                                                      % Function F of the equation F(x) = b: a function handle or a symbolic expression. <@Type> function_handle | sym
        NRMJac                                                                      % Jacobian of NRMFcn; computed by numerical differentiation when not given. <@Type> function_handle
        NRMVal                                                                      % Right-hand side b of F(x) = b; zeros (F(x) = 0) when not given. <@Type> double (n x 1)
        ConvTol (1,1) double = GUILDA.config("NewtonRaphsonMethod","ConvTol");      % Absolute tolerance of the step dx for convergence.
        MaxIter (1,1) double = GUILDA.config("NewtonRaphsonMethod","MaxIter");      % Maximum number of iterations (a warning when reached).
        InitVal (:,1) double = GUILDA.config("NewtonRaphsonMethod","InitVal");      % Initial value of x.
        Increment (1,1) double = GUILDA.config("NewtonRaphsonMethod","Increment");  % Step of the numerical differentiation.
        StepSize (1,1) double = GUILDA.config("NewtonRaphsonMethod","StepSize");    % Factor of the update x = x - StepSize*dx; large values may not converge.
    end
    
    methods
        function obj = NewtonRaphsonMethod(opt)            
        % Create a Newton-Raphson solver.
        %
        % The Name-Value options are the public properties; the others keep the defaults of
        % GUILDA.config("NewtonRaphsonMethod").
            arguments (Input)
                opt.?NewtonRaphsonMethod
            end            
            arguments (Output)
                obj  % Newton-Raphson solver.
            end

            fnames = fieldnames(opt);
            argi = 1;
            while argi <= numel(fnames)
                fname_i = fnames{argi};
                obj.(fname_i) = opt.(fname_i);

                argi = argi + 1;
            end            

            if isempty(obj.NRMJac)
                func  = obj.NRMFcn;
                delta = obj.Increment;
                switch class(func)
                    case {'function_handle','double'}                        
                        obj.NRMJac = @(x) obj.numerical_differentiation(x,func,delta);
                    case 'sym'
                        % The symbolic path is optional and needs Symbolic Math Toolbox.
                        if ~NewtonRaphsonMethod.has_symbolic()
                            error(msg("GUILDA:NewtonRaphsonMethod:SymbolicUnavailable"));
                        end
                        sv_x = symvar(func);
                        Jacobian = jacobian(func,sv_x);
        
                        obj.NRMFcn = matlabFunction(func    ,"Vars",sv_x);
                        obj.NRMJac = matlabFunction(Jacobian,"Vars",sv_x);                    
                    otherwise
                        error(msg("GUILDA:NewtonRaphsonMethod:InvalidInput"))
                end                
            end

            if isempty(obj.NRMVal)                
                obj.NRMVal = zeros(size(obj.InitVal));
            end
            
        end
    end

    methods (Static,Access=private,Hidden)
        l = has_symbolic()
    end

    methods (Access=private,Hidden)
        Jacobian = numerical_differentiation(obj, x, OBJFcn, del)
        flag = isConvergence(obj,dx,Tol)
    end

    methods (Access=public)        
        [xi,iteration] = solve(obj)
    end
end
