function flag = validate(obj, l_message, opt)
% Check the model functions of every component and local controller of the network at the equilibrium.
%
% Runs `Component.validate` and `LocalController.validate` (without their messages) on
% every component and local controller, in the order of the variable map (bus by bus,
% each component with its local controllers depth first), and collects the results in
% one table `flag.summary`, one row per element:
%
% - `Tag`, `Class`, `Kind` ("Component", "LocalController" or "GlobalController")
% - `Status`: "PASS", "FAIL", or "NOT CHECKED" for the global controllers (they have no
%   validate)
% - `MaxResidual`: the largest residual at the equilibrium (dx, and for a component the
%   bus current I); 0 when there is nothing to compare
% - `MaxJacobianDiff`: the largest difference between the analytic Jacobian blocks and
%   the finite differences, each divided by 1 + |J| (J: the analytic entry); 0 when there
%   is nothing to compare. The tables of `flag.element` keep the absolute differences.
% - `Failed`: the contract items that are FAIL, then the blocks over the tolerance or
%   not computable (e.g. "dx", "Axx"); "validate stopped: <id>" when the check itself stopped
%
% An element is FAIL when a contract item is FAIL, when a residual or a Jacobian
% difference is NaN (not computable), or when it is larger than its tolerance. The
% default tolerances are those of the model contract tests of the verification suite:
% 1e-8 for the residuals (the equilibrium of initialize solves them to rounding error)
% and 1e-5 for the Jacobians. The Jacobian tolerance is relative to 1 + |J|, because the
% truncation error of the central differences grows with the entry: a load of small
% impedance (|dI/du| about 3e3 in IEEE68bus) differs by about 3e-4 with a correct
% Jacobian, while a wrong entry differs by about 1 + |J|.
%
% The network must be up to date, as for `LocalController.validate`: before
% net.initialize(), or after an edit that made the network, a component or a controller
% stale (including edited inputs), it stops with GUILDA:PowerNetwork:ValidateStale
% ("Run net.initialize() first").
%
% With l_message true, the summary table is displayed, and for each FAIL element only
% its failed contract items and the tables over the tolerance.
%
% <@Examples>
% ```matlab
% net = network.Tutorial10bus();
% net.initialize();
% net.validate();                              % summary and the details of FAIL elements
% flag = net.validate(false);
% flag.summary(flag.summary.Status == "FAIL", :)
% flag.element{"B001SG1"}.contract             % the validate result of one element
% ```
%
% See also Component.validate, LocalController.validate
%
% <@Group> Queries and checks
    arguments (Input)
        obj
        l_message (1,1) logical = true  % Display the summary and the FAIL elements.
        opt.Tolerance (1,2) double {mustBePositive} = [1e-8, 1e-5]  % Tolerances [residual, Jacobian difference].
    end
    arguments (Output)
        flag  % Struct: summary (table, one row per element), element (dictionary from the tag to the validate result of each checked element, a cell).
    end

    simulateFcn_check(obj, "GUILDA:PowerNetwork:ValidateStale");

    [c_elem, sv_kind] = element_list(obj);
    lv_keep = ismember(sv_kind, ["component","local","global"]);
    c_elem  = c_elem(lv_keep);
    sv_kind = sv_kind(lv_keep);
    n = numel(c_elem);

    sv_tag    = string(cellfun(@(e) e.s_tag, c_elem, "UniformOutput", false));
    sv_class  = string(cellfun(@class, c_elem, "UniformOutput", false));
    sv_kindEl = replace(sv_kind, ["component","local","global"], ["Component","LocalController","GlobalController"]);
    sv_status = repmat("NOT CHECKED", n, 1);
    rv_res    = nan(n,1);
    rv_jac    = nan(n,1);
    sv_failed = strings(n,1);
    c_flag    = cell(n,1);
    c_scale   = cell(n,1);
    sv_res = ["dx","I"];
    sv_jac = ["Axx","Bxv","Bxu","Cix","Div","Diu","Cyx","Dyv","Dyu"];

    for k = find(sv_kind ~= "global")'
        try
            f = c_elem{k}.validate(false);
        catch ME
            sv_status(k) = "FAIL";
            s_id = string(ME.identifier);
            if s_id == ""   % error(msg(...)) of GUILDA has no identifier
                s_id = strtok(string(ME.message), newline);
            end
            sv_failed(k) = "validate stopped: " + s_id;
            continue
        end
        c_flag{k} = f;

        % |J| of the analytic blocks at the point of validate (the equilibrium); a block
        % that cannot be computed or has the wrong size keeps the absolute difference
        elem = c_elem{k};
        rv_x = elem.rv_Xequilibrium;
        rv_V = [real(elem.c_Vequilibrium); imag(elem.c_Vequilibrium)];
        rv_u = elem.rv_Uequilibrium;
        if sv_kind(k) == "component"
            c_jac = {elem.f_JacobiDx, ["Axx","Bxv","Bxu"], {0,rv_x,rv_V,rv_u}; ...
                     elem.f_JacobiI,  ["Cix","Div","Diu"], {0,rv_x,rv_V,rv_u}; ...
                     elem.f_JacobiY,  ["Cyx","Dyv"],       {0,rv_x,rv_V}};
        else
            c_jac = {elem.f_JacobiDx, ["Axx","Bxv","Bxu"], {0,rv_x,rv_V,rv_u}; ...
                     elem.f_JacobiY,  ["Cyx","Dyv","Dyu"], {0,rv_x,rv_V,rv_u}};
        end
        sct_scale = struct();
        for m = 1:height(c_jac)
            sv_blk = c_jac{m,2};
            c_J = cell(1, numel(sv_blk));
            try
                [c_J{:}] = c_jac{m,1}(c_jac{m,3}{:});
            catch
                continue
            end
            for b = 1:numel(sv_blk)
                if isfield(f, sv_blk(b)) && numel(c_J{b}) == numel(f.(sv_blk(b)))
                    sct_scale.(sv_blk(b)) = reshape(abs(full(c_J{b})), size(f.(sv_blk(b))));
                end
            end
        end
        c_scale{k} = sct_scale;

        sv_bad = string(f.contract.Properties.RowNames(f.contract.status == "FAIL"));
        [rv_res(k), sv_over] = block_max(f, sv_res, opt.Tolerance(1), struct());
        sv_bad = [sv_bad; sv_over]; %#ok<AGROW>
        [rv_jac(k), sv_over] = block_max(f, sv_jac, opt.Tolerance(2), sct_scale);
        sv_bad = [sv_bad; sv_over]; %#ok<AGROW>
        sv_failed(k) = join(sv_bad, "; ");
        if isempty(sv_bad)
            sv_status(k) = "PASS";
            sv_failed(k) = "";
        else
            sv_status(k) = "FAIL";
        end
    end

    lv_checked = ~cellfun(@isempty, c_flag);
    flag = struct();
    flag.summary = table(sv_tag, sv_class, sv_kindEl, sv_status, rv_res, rv_jac, sv_failed, ...
        VariableNames=["Tag","Class","Kind","Status","MaxResidual","MaxJacobianDiff","Failed"]);
    flag.element = dictionary(sv_tag(lv_checked), c_flag(lv_checked));

    % message
    if l_message
        disp(repmat('=',1,100))
        fprintf("Validate of '%s': %d PASS, %d FAIL, %d NOT CHECKED (Tolerance: residual %g, Jacobian %g)\n\n", ...
            obj.s_tag, sum(sv_status == "PASS"), sum(sv_status == "FAIL"), sum(sv_status == "NOT CHECKED"), ...
            opt.Tolerance(1), opt.Tolerance(2));
        disp(flag.summary)
        for k = find(sv_status == "FAIL")'
            disp(repmat('-',1,100))
            fprintf("%s (%s): %s\n\n", sv_tag(k), sv_class(k), sv_failed(k));
            f = c_flag{k};
            if isempty(f)
                continue
            end
            lv = f.contract.status == "FAIL";
            if any(lv)
                disp(">> Contract items that are FAIL" + newline)
                disp(f.contract(lv,:))
            end
            [~, sv_over] = block_max(f, sv_res, opt.Tolerance(1), struct());
            for fn = sv_over'
                disp(">> " + fn + " (residual over the tolerance " + opt.Tolerance(1) + " or NaN)" + newline)
                disp(f.(fn))
            end
            [~, sv_over] = block_max(f, sv_jac, opt.Tolerance(2), c_scale{k});
            for fn = sv_over'
                disp(">> " + fn + " (absolute difference; over " + opt.Tolerance(2) + "*(1+|J|) or NaN)" + newline)
                disp(f.(fn))
            end
        end
        disp(repmat('=',1,100))
    end
end


function [r_max, sv_over] = block_max(f, sv_fn, r_tol, sct_scale)
    % Largest value of the tables sv_fn of a validate result, each divided by 1 + the
    % scale of sct_scale when it has the table (NaN when one is NaN, 0 when there is
    % none), and the names of the tables over the tolerance or with NaN
    arguments (Input)
        f                   % Result of Component.validate or LocalController.validate.
        sv_fn (1,:) string  % Field names of the tables.
        r_tol (1,1) double  % Tolerance.
        sct_scale struct    % |J| of the tables that are relative (fields named as the tables).
    end
    arguments (Output)
        r_max (1,1) double     % Largest value.
        sv_over (:,1) string   % Tables over the tolerance or with NaN.
    end
    r_max   = 0;
    sv_over = strings(0,1);
    for fn = sv_fn
        if ~isfield(f, fn) || isempty(f.(fn)) || width(f.(fn)) == 0
            continue
        end
        rm = f.(fn){:,:};
        if isfield(sct_scale, fn)
            rm = rm ./ (1 + sct_scale.(fn));
        end
        r_blk = max(rm, [], "all", "includemissing");
        r_max = max(r_max, r_blk, "includemissing");
        if isnan(r_blk) || r_blk > r_tol
            sv_over(end+1,1) = fn; %#ok<AGROW>
        end
    end
end
