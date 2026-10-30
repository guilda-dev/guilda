function varargout = build_opf_problem(obj, varargin)
% Build the OPF problem of the network (net.optimize_powerflow solves it).
%   prob = net.build_opf_problem(Method="DC OPF")
%   [prob, x0] = net.build_opf_problem(Method="AC OPF", validate=true)
% Method is "ELD", "DC OPF" or "AC OPF" (default); with no output the problem is displayed.
    varargin = v3_opf_args(varargin, "BuildOpfProblemMethods");    % COMPAT(v3)
    [varargout{1:nargout}] = build_problem(obj, varargin{:});
end


function varargout = build_problem(obj,options)
arguments
    obj 
    options.Method   (1,1) string {mustBeMember(options.Method,["ELD","DC OPF","AC OPF"])} = "AC OPF";
    options.validate (1,1) logical = false;
end
    
    % make model description
    tab_OPF.Bus       = tools.vcellfun(@(b) b.tab_parameter, obj.a_Bus);
    tab_OPF.Bus       = tab_OPF.Bus(:,["operation","powerflow"]);
    tab_OPF.Bus.Properties.RowNames = string(obj.a_Bus);

    a_Com             = tools.vcellfun(@(b) b.a_Component, obj.a_Bus);
    tab_OPF.Component = tools.vcellfun(@(c) c.tab_parameter(:,["OPF","operation"]), a_Com);
    tab_OPF.Component.Properties.RowNames = string(a_Com);

    tab_OPF.Branch    = tools.vcellfun(@(b) b.tab_parameter, obj.a_Branch);
    tab_OPF.Branch    = tab_OPF.Branch(:,"operation");
    tab_OPF.Branch.Properties.RowNames = string(obj.a_Branch);
    
    str_text = newline+"Optimal Poer Flow ("+options.Method+")"+newline...
             + string(repmat('=',1,100))+newline+newline;
    for str_tag = ["Bus","Component","Branch"]
        str_text = str_text...
                 + "<<"+str_tag+" OPF setting>>"+newline...
                 + formattedDisplayText(tab_OPF.(str_tag))+newline+newline;
    end
    str_text = str_text + "<<Network Topology>>"+newline...
                        + obj.disp_tree + newline...
                        +string(repmat('=',1,100))+newline;


    % define optimproblem
    x0    = struct();
    const = struct();
    Vvar  = struct();
    prob = optimproblem("ObjectiveSense","minimize",...
                        "Objective"     ,struct("GenCost",0),...
                        "Description"   ,str_text);
    if options.Method=="ELD"
        const.P = 0;
    end

    a_Bus = obj.a_Bus;
    a_Branch = obj.a_Branch;

    for i = 1:numel(a_Bus)
        [prob, x0, const, Vvar] = a_Bus{i}.build_opf_problem(prob,x0,const,Vvar,"methods",options.Method);
    end

    % Reference angle: the slack bus (the first bus if none is set) keeps its power-flow Varg.
    % net.set_opffcn(DefaultConstraint=false) removes it.
    if options.Method ~= "ELD" && obj.s_opffcn.DefaultConstraint
        i_ref = find(cellfun(@(b) b.l_isSlack, a_Bus), 1);
        if isempty(i_ref); i_ref = 1; end
        Varg_ref = a_Bus{i_ref}.para_powerflow.Varg;
        if isnan(Varg_ref); Varg_ref = 0; end
        Vref = Vvar.(string(a_Bus{i_ref}));
        prob.Constraints.VargRef = Vref("Varg") == Varg_ref;
    end
    for i = 1:numel(a_Branch)
        [prob, x0, const] = a_Branch{i}.build_opf_problem(prob,x0,const,Vvar,"methods",options.Method);
    end

    str_const = fieldnames(const);
    for i = 1:numel(str_const)
        str_coni = str_const{i};
        prob.Constraints.("balanced"+str_coni) = const.(str_coni) == 0;
    end

    % network-wide set_opffcn terms (variables of all objects, addressed by tag)
    prob = opffcn.apply(obj, prob, options.Method, Vvar);

    switch nargout
        case 0; disp(prob);
        case 1; varargout{1} = prob;
        case 2; varargout{1} = prob;
                varargout{2} = x0;
    end

    if options.validate
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