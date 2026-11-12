function varargout = build_opf_problem(obj, varargin)
% Build the optimization problem of the optimal power flow without solving it.
%
% Builds the problem that `net.calculate_optimal_powerflow` solves (SolverOPF.build_problem), so
% that it can be inspected or modified before solving it with
% net.calculate_optimal_powerflow(Problem=prob, InitialPoint=x0). The settings are the
% OptimalPowerFlow section of GUILDA.setting and the conditions kept by net.solver_OPF;
% Name-Value options override them for this call only.
% With no output the problem is displayed.
% Constraint names: balancedP_<bus>, balancedQ_<bus> (balancedP in "ELD"), VargRef,
% VargMax1_<branch>, VargMax2_<branch>, defIre_, defIim_, defP_, defQ_, Imax_, Smax_
% (<branch>_<bus>), plus the names of Constraint. Variables are named by the tags of the
% buses (Varg, V), components (P, Q) and branch ends (<branch>_<bus>: P, Q, Ireal, Iimag
% flowing into the bus).
%
% Name-Value options:
%
% - `Method` — "ELD", "DC OPF" or "AC OPF". Default: GUILDA.setting ("AC OPF").
% - `Cost` — Function handle @(v, p) returning a scalar added to the objective (net.solver_OPF.Cost; [] = none).
% - `Constraint` — Function handle @(v, p) returning struct(name1, constraint1, ...) added to the problem (net.solver_OPF.Constraint; [] = none).
% - `DefaultCost` — false leaves out the costs of tab_parameter.OPF (net.solver_OPF.DefaultCost).
% - `ReferenceBus` — Bus with a fixed angle: "auto", a bus tag or "none" (net.solver_OPF.ReferenceBus).
% - `validate` — Check that the initial point x0 fits the problem. Default: false.
%
% <@Examples>
% ```matlab
% prob = net.build_opf_problem(Method="DC OPF");
% [prob, x0] = net.build_opf_problem(Method="AC OPF", validate=true);
% % Add a constraint and solve the modified problem
% [prob, x0] = net.build_opf_problem(Method="DC OPF");
% prob.Constraints.Cap = prob.Variables.B001SG1 <= 0.4;
% res = net.calculate_optimal_powerflow(Method="DC OPF", Problem=prob, InitialPoint=x0);
% ```
%
% See also PowerNetwork.calculate_optimal_powerflow, SolverOPF.build_problem
%
% <@Group> OPF
    arguments (Input)
        obj
    end
    arguments (Input, Repeating)
        varargin   % Name-Value options Method, Cost, Constraint, DefaultCost, ReferenceBus and validate.
    end
    arguments (Output, Repeating)
        varargout   % prob (the optimproblem), then x0 (the initial point as a struct of the variables).
    end
    varargin = v3_opf_args(varargin, "BuildOpfProblemMethods");    % COMPAT(v3)
    [c_nv, l_validate] = take_validate(varargin);

    % only the options of the problem (not the solver options such as Tolerance)
    sct_map = SolverOPF.OptionMap;
    sct_map = rmfield(sct_map, setdiff(fieldnames(sct_map), ["Method","Cost","Constraint","DefaultCost","ReferenceBus"]));
    tools.resolve_options(obj.solver_OPF.get_options(), sct_map, c_nv);
    sct_options = obj.solver_OPF.get_options(c_nv);

    [prob, x0] = obj.solver_OPF.build_problem(obj, sct_options);

    switch nargout
        case 0; disp(prob);
        case 1; varargout{1} = prob;
        case 2; varargout{1} = prob;
                varargout{2} = x0;
    end

    if l_validate
        validate(prob,x0)
    end
end


function [c_nv, l_validate] = take_validate(c_in)
% Separates the option validate from the problem options
    c_nv       = c_in;
    l_validate = false;
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_take = false(size(c_in));
    for k = 1:2:numel(c_in)
        if (ischar(c_in{k}) || isstring(c_in{k})) && strcmpi(c_in{k}, "validate")
            lv_take(k:k+1) = true;
            l_validate = validate_flag(c_in{k+1});
        end
    end
    c_nv = c_in(~lv_take);
end

function l = validate_flag(l)
    arguments (Input)
        l (1,1) logical   % Value of validate.
    end
    arguments (Output)
        l                 % The value as a logical scalar.
    end
end


function validate(prob,x0_struct)
    % 1. Convert the initial point x0 struct into the format
    %    expected by the 'evaluate' function (variable names and their values).
    
    % 2. Retrieve constraints from the problem object.
    % Constraints are stored in prob.Constraints.
    constraint_names = fieldnames(prob.Constraints);
    
    % 3. Initialize a list to store constraints that produced NaN/Inf.
    problem_constraints = {};
    all_constraints_valid = true;
    
    % 4. Loop through each constraint and evaluate it.
    disp('--- Initial Point Evaluation Results for Nonlinear Constraints ---');
    
    for k = 1:length(constraint_names)
        name = constraint_names{k};
        constraint = prob.Constraints.(name);
        
        % Use optim.problemdef.evaluate to calculate the constraint value
        % (LHS - RHS) using the initial values in x0_struct.
        try
            % Evaluate the constraint expression at the initial point x0
            evaluated_values = evaluate(constraint, x0_struct);
            
            % Check for NaN or Inf values
            is_invalid = any(isnan(evaluated_values(:))) || any(isinf(evaluated_values(:)));
            
            if is_invalid
                all_constraints_valid = false;
                problem_constraints{end+1} = name;
                
                % Display error message
                disp(['[ISSUE FOUND] Constraint Name: ', name]);
                disp('  Evaluation resulted in NaN/Inf:');
                disp(evaluated_values);
            % else
                % Optional: Displaying normal constraints can be omitted for brevity
                % disp(['[OK] Constraint Name: ', name]);
            end
            
        catch ME
            % Handle runtime errors during evaluation (e.g., division by zero, log(0))
            all_constraints_valid = false;
            problem_constraints{end+1} = name;
            disp(['[EVALUATION ERROR] Constraint Name: ', name]);
            disp(['  Error Message: ', ME.message]);
        end
    end
    
    disp('------------------------------------------------------------------');
    
    % 5. Summary of the final results
    if all_constraints_valid
        disp('✅ All nonlinear constraints returned valid numerical values (real numbers) at the initial point x0.');
        disp('   The error might stem from issues other than constraint evaluation.');
    else
        disp('❌ Problems found in the following nonlinear constraints at the initial point x0:');
        for i = 1:length(problem_constraints)
            disp(['   - ', problem_constraints{i}]);
        end
        disp('   Please check the formulation of these constraints and adjust the initial point x0.');
    end
end