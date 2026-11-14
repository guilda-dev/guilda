function varargout = build_opf_problem(obj, opt)
% Build the optimization problem of the optimal power flow without solving it.
%
% Builds the problem that `net.calculate_optimal_powerflow` solves, so that it can be
% inspected or modified before solving it with
% net.calculate_optimal_powerflow(Problem=prob, InitialPoint=x0). It is the first step of
% calculate_optimal_powerflow: the data of the problem are collected here (the tables of
% net.get_opf_condition, the base and the reference bus, "auto" resolved) and
% net.solver_OPF builds the problem from them (SolverOPF.build_problem). Method defaults
% to the OptimalPowerFlow section of GUILDA.setting; the other options are options of the
% call only. Options not listed below stop with the MATLAB error of an unknown name.
% With no output the problem is displayed.
% Constraint names: balancedP_<bus>, balancedQ_<bus> (balancedP in "ELD"), VargRef,
% VargMax1_<branch>, VargMax2_<branch>, defIre_, defIim_, defP_, defQ_, Imax_, Smax_
% (<branch>_<bus>), plus the names of Constraint. Variables are named by the tags of the
% buses (Varg, V), components (P, Q) and branch ends (<branch>_<bus>: P, Q, Ireal, Iimag
% flowing into the bus). The initial point x0 is the flat start (see SolverOPF).
% The third output sct_data holds the data the problem was built from:
%
% - `Bus`, `Component`, `Branch` — Tables of net.get_opf_condition (row names = tags).
% - `base` — Base of the network (baseMVA, Hz; p.base of Cost and Constraint).
% - `ReferenceBus` — Bus with a fixed angle: the bus tag ("auto" resolved: the slack bus if one is set, else the first bus) or "none".
%
% Name-Value options:
%
% - `Method` — "ELD", "DC OPF" or "AC OPF". Default: GUILDA.setting ("AC OPF").
% - `Cost` — Function handle @(v, p) returning a scalar added to the objective; [] = none. Default: [].
% - `Constraint` — Function handle @(v, p) returning struct(name1, constraint1, ...) added to the problem; [] = none. Default: [].
% - `DefaultCost` — false leaves out the costs of tab_parameter.OPF. Default: true.
% - `ReferenceBus` — Bus with a fixed angle: "auto", a bus tag or "none". Default: "auto".
% - `validate` — Check that the initial point x0 fits the problem. Default: false.
%
% <@Examples>
% ```matlab
% prob = net.build_opf_problem(Method="DC OPF");
% [prob, x0] = net.build_opf_problem(Method="AC OPF", validate=true);
% [~, ~, sct_data] = net.build_opf_problem();        % sct_data.ReferenceBus: the bus with a fixed angle
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
        opt.Method (1,1) string {mustBeMember(opt.Method, ["ELD","DC OPF","AC OPF"])} = GUILDA.config("OptimalPowerFlow", "Method") % Formulation.
        opt.Cost {mustBeHandleOrEmpty} = [] % User cost @(v, p) added to the objective; [] for none.
        opt.Constraint {mustBeHandleOrEmpty} = [] % User constraints @(v, p) returning struct(name, constraint, ...); [] for none.
        opt.DefaultCost (1,1) logical = true % Add the cost of tab_parameter.OPF of every component.
        opt.ReferenceBus (1,1) string = "auto" % Bus with a fixed angle: "auto", a bus tag or "none".
        opt.validate (1,1) logical = false % Check that x0 fits the problem.
    end
    arguments (Output, Repeating)
        varargout   % prob (the optimproblem), x0 (the initial point as a struct of the variables), then sct_data (the data of the problem: Bus, Component, Branch, base, ReferenceBus).
    end
    % Data of the problem: the tables of the network, its base and the reference bus
    sct_data = obj.get_opf_condition(Display=false);
    sct_data.base = table2struct(obj.tab_parameter.base);
    sct_data.ReferenceBus = opt.ReferenceBus;
    if opt.ReferenceBus == "auto"
        i_ref = find(cellfun(@(b) b.l_isSlack, obj.a_Bus), 1);   % the slack bus, else the first bus
        if isempty(i_ref); i_ref = 1; end
        if isempty(obj.a_Bus)
            sct_data.ReferenceBus = "none";
        else
            sct_data.ReferenceBus = string(obj.a_Bus{i_ref});
        end
    end

    sct_options = rmfield(opt, "validate");
    sct_options.base = sct_data.base;
    sct_options.ReferenceBus = sct_data.ReferenceBus;
    [prob, x0] = obj.solver_OPF.build_problem(sct_data.Bus, sct_data.Component, sct_data.Branch, sct_options);

    if nargout == 0
        disp(prob);
    end
    varargout = {prob, x0, sct_data};
    varargout = varargout(1:nargout);

    if opt.validate
        validate(prob,x0)
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