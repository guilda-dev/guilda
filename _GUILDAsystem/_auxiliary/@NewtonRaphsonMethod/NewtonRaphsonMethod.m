classdef (Sealed = true) NewtonRaphsonMethod < auxiliary
% Newton-Raphson solver of a nonlinear equation F(x) = b.
%
% The continuation power flow uses it as its corrector. Give the equation and the options
% as Name-Value arguments of the constructor (they are the public properties), then call
% solve. Without NRMJac the Jacobian is computed by central differences with step
% Increment.
%
% <@Examples>
% ```matlab
% nrm = NewtonRaphsonMethod(NRMFcn=@(x) [x(1)^2 + x(2); x(2)^3], ...
%                           NRMVal=[2; 1], InitVal=[0.5; 0.5]);
% [x, n_iter] = nrm.solve();
% ```
%
% See also ContinuationPowerFlow
    
    properties (Access=public) % Equation
        % Function F of the equation F(x) = b.
        % A function handle, or a symbolic expression (needs Symbolic Math Toolbox; GUILDA
        % itself always passes function handles).
        % <@Type> function_handle | sym
        NRMFcn 

        % Jacobian of NRMFcn.
        % Computed by numerical differentiation when not given; giving it is usually faster.
        % <@Type> function_handle
        NRMJac          

        % Right-hand side b of F(x) = b; zeros (F(x) = 0) when not given.
        % <@Type> double (n x 1)
        NRMVal 
        
        ConvTol   (1,1) double  = GUILDA.config("NewtonRaphsonMethod","ConvTol"  ); % Absolute tolerance of the step dx for convergence.
        MaxIter   (1,1) double  = GUILDA.config("NewtonRaphsonMethod","MaxIter"  ); % Maximum number of iterations (a warning when reached).
        InitVal   (:,1) double  = GUILDA.config("NewtonRaphsonMethod","InitVal"  ); % Initial value of x.
        Increment (1,1) double  = GUILDA.config("NewtonRaphsonMethod","Increment"); % Step of the numerical differentiation.
        StepSize  (1,1) double  = GUILDA.config("NewtonRaphsonMethod","StepSize" ); % Factor of the update x = x - StepSize*dx; large values may not converge.
    end
    
    methods
        function obj = NewtonRaphsonMethod(opt)            
        % Create a Newton-Raphson solver.
        %
        % The Name-Value options are the public properties; the others keep the defaults of
        % GUILDA.config("NewtonRaphsonMethod").
            arguments                
                opt.?NewtonRaphsonMethod
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
                            error('GUILDA:NewtonRaphsonMethod:SymbolicUnavailable', '%s', ...
                                msg('GUILDA:NewtonRaphsonMethod:SymbolicUnavailable'));
                        end
                        sv_x = symvar(func);
                        Jacobian = jacobian(func,sv_x);
        
                        obj.NRMFcn = matlabFunction(func    ,"Vars",sv_x);
                        obj.NRMJac = matlabFunction(Jacobian,"Vars",sv_x);                    
                    otherwise
                        error(msg('GUILDA:NewtonRaphsonMethod:InvalidInput'))
                end                
            end

            if isempty(obj.NRMVal)                
                obj.NRMVal = zeros(size(obj.InitVal));
            end
            
        end
    end

    methods (Static,Access=private,Hidden)
        function l = has_symbolic()
            l = license('test','Symbolic_Toolbox') && ~isempty(ver('symbolic'));
        end
    end

    methods (Access=private,Hidden)
        function Jacobian = numerical_differentiation(obj, x, OBJFcn, del) %#ok                                               
            nx  = numel(x);
            Jacobian = cell2mat( arrayfun(@(ITER) ( OBJFcn(x+[zeros(ITER-1,1);del;zeros(nx-ITER,1)]) - ...
                OBJFcn(x-[zeros(ITER-1,1);del;zeros(nx-ITER,1)]) ) / 2 / del, 1:nx, 'UniformOutput', false) );
        end
        function flag = isConvergence(obj,dx,Tol) %#ok
            flag = all(abs(dx) < Tol);
        end
    end

    methods (Access=public)        

        function [xi,iteration] = solve(obj)            
        % Solve F(x) = b from InitVal.
        %
        % Iterates x = x - StepSize * (J(x) \ (F(x) - b)) until every element of the step is
        % smaller than ConvTol, or MaxIter iterations (then with a warning).
        %
        % Outputs:
        % - `xi`: Solution x.
        % - `iteration`: Number of iterations.

            AbsTol = obj.ConvTol;
            Gamma  = obj.StepSize;
            MaxIt  = obj.MaxIter;

            NRMF = obj.NRMFcn;
            NRMJ = obj.NRMJac;
            NRMV = obj.NRMVal;

            xi = obj.InitVal;

            isConvergence = false;
            iteration     = 1;
            while ~isConvergence && iteration <= MaxIt
                Ferror = NRMF(xi) - NRMV;    
                Jacobi = NRMJ(xi);
                dx = Jacobi \ Ferror;

                if obj.isConvergence(dx,AbsTol)
                    isConvergence = true;                
                else
                    xi = xi - Gamma * dx;
                    iteration = iteration + 1;
                end                
            end

            if iteration >= MaxIt                
                warning(msg('GUILDA:NewtonRaphsonMethod:MaxIteration'))            
            end
        end        
    end
end