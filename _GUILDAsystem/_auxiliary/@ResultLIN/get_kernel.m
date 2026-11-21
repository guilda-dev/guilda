function sct_kernel = get_kernel(obj, opt)
% Get the kernel of the Jacobian of the DAE: the rotation of the phases.
%
% J is the full state matrix A of get_ss("DAE") over [x; v] (the dynamic states and the
% bus variables), in the Port of the result; for Port "I" it is computed in Port "PQ",
% where a rotation of all phases is a change of the angles only. The kernel is found from
% the singular values of J: those up to Tolerance times the largest. Both bases are
% returned (variables x n_dim, the rows in the order of sv_state):
%
% - rm_right: J r = 0. Turning every phase of an island by the same angle (the bus
%   angles theta and the generator angles delta) leaves every equation unchanged, so the
%   right kernel spans these rotations. Each column is the indicator of one island: 1 on
%   its phase variables, 0 elsewhere; the columns are in the order of the first phase
%   variable of each island.
% - rm_left: w' J = 0, the dual basis of the right one: rm_left' * rm_right = I. Its
%   entries are those of the equation rows of the variables (the state equation of a
%   state, the P balance of a bus angle).
%
% A phase variable is a variable whose right-kernel value is 1. tab_phase has one row per
% phase variable: Index (the row of the variable in sv_state), Name, Owner (the tag of the
% bus, or of the component or controller of the state), Kind ("Bus", "Component",
% "LocalController" or "GlobalController"), Kernel (the column of the bases), Right (the
% entry of rm_right, 1) and Left (the entry of rm_left at the variable).
%
% A kernel that has no rotation form (it is not spanned by indicators of phase variables)
% is returned as orthonormal bases, with an empty tab_phase; when the left basis cannot be
% dual to the right one (w' r singular), rm_left is orthonormal. s_message says so. A
% Jacobian without a kernel (n_dim 0, e.g. a model with an infinite bus) returns empty
% bases and tab_phase, and s_message says so; s_message is "" otherwise.
%
% Index chooses the section (default res.Index; see ResultLIN), and Time, when given, the
% section whose time rv_t is nearest to it. Index "all" returns a 1 x n_t struct array.
% Only a result of the network (output.s_layer "PowerNetwork") has a DAE with bus
% variables; another layer stops with GUILDA:ResultLIN:NetworkOnly.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();
% res = net.get_sys();
% sct = res.get_kernel();                  % rotation of the phases
% sct.tab_phase                            % the bus angles and generator angles, Right and Left
% sct.rm_left' * sct.rm_right              % the dual bases: I
% sct.s_message                            % "" when the kernel has the rotation form
% ```
%
% See also ResultLIN.get_ss, ResultLIN.get_reduced_matrix, ResultLIN.get_mode
    arguments (Input)
        obj
        opt.Tolerance (1,1) double {mustBePositive} = 1e-8  % Singular values of J up to Tolerance times the largest are the kernel.
        opt.Index {mustBeSection} = obj.Index   % Section (1 ... numel(rv_t)) or "all" (a struct array, one per section); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}      % [s] Time: the section whose rv_t is nearest; overrides Index.
    end
    arguments (Output)
        sct_kernel struct   % rm_right, rm_left (variables x n_dim), sv_state (variables), tab_phase, n_dim, s_port, s_message (1 x n_t for Index "all").
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "get_kernel"))
    end
    s_port = "PQ";
    if isfield(obj.options, "Port") && obj.options.Port ~= "I"
        s_port = obj.options.Port;
    end
    iv_sec = section_list(obj, opt);
    n_s = numel(iv_sec);
    c_kernel  = cell(1, n_s);
    for i = 1:n_s
        sys = obj.get_ss("DAE", Port=s_port, Index=iv_sec(i), Format="struct");
        J = full(sys.A);
        sv_state = sys.StateName;
        n = size(J, 1);
        [rm_U, rm_S, rm_V] = svd(J);
        rv_s = diag(rm_S);
        n_dim = nnz(rv_s <= opt.Tolerance * max([rv_s; eps]));
        R = rm_V(:, n-n_dim+1:n);
        Wl = rm_U(:, n-n_dim+1:n);

        % the indicator of each island: the rows of the phase variables of an island are equal
        tab_phase = table('Size', [0 7], 'VariableTypes', ["double","string","string","string","double","double","double"], ...
            'VariableNames', ["Index","Name","Owner","Kind","Kernel","Right","Left"]);
        l_rot = false;
        s_message = "";
        if n_dim == 0
            s_message = sprintf("The Jacobian of the DAE has no kernel (smallest singular value %.3g, %.3g times the largest).", ...
                min(rv_s), min(rv_s) / max([rv_s; eps]));
        else
            rv_norm = vecnorm(R, 2, 2);
            iv_phase = find(rv_norm > 1e-6 * max(rv_norm));
            [~, ~, iv_group] = uniquetol(R(iv_phase,:), 1e-6, "ByRows", true, "DataScale", max(rv_norm));
            [~, iv_first] = unique(iv_group, "stable");
            iv_group = arrayfun(@(g) find(iv_group(iv_first) == g), iv_group);   % islands in the order of their first variable
            n_group = max([0; iv_group]);
            R_ind = zeros(n, n_group);
            R_ind(sub2ind(size(R_ind), iv_phase, iv_group)) = 1;
            l_rot = n_group == n_dim && norm(R - R_ind * (R_ind \ R)) <= 1e-6 && norm(J * R_ind) <= sqrt(opt.Tolerance) * max(rv_s);
            if l_rot
                R = R_ind;
                sv_owner = state_owner(obj, sv_state);
                tab_owner = obj.c_section{iv_sec(i)}.tab_owner;
                [~, iv_own] = ismember(sv_owner(iv_phase), tab_owner.Owner);
                sv_kind = repmat("Bus", numel(iv_phase), 1);
                for j = 1:numel(iv_phase)
                    if iv_own(j) > 0 && tab_owner.Class(iv_own(j)) ~= "Bus"
                        sv_super = [tab_owner.Class(iv_own(j)); reshape(string(superclasses(char(tab_owner.Class(iv_own(j))))), [], 1)];
                        sv_kind(j) = sv_super(find(ismember(sv_super, ["Component","LocalController","GlobalController"]), 1));
                    end
                end
                tab_phase = table(iv_phase, sv_state(iv_phase), sv_owner(iv_phase), sv_kind, iv_group, ones(numel(iv_phase),1), ...
                    zeros(numel(iv_phase),1), 'VariableNames', ["Index","Name","Owner","Kind","Kernel","Right","Left"]);
            else
                s_message = sprintf("The kernel of the Jacobian (dimension %d) is not spanned by rotations of phase variables; the bases are orthonormal.", n_dim);
            end
        end

        if n_dim > 0 && l_rot
            M = R' * Wl;
            if rcond(M) > 1e-12
                Wl = Wl / M;
            else
                s_message = sprintf("The left kernel is orthogonal to the rotations (w'' r singular, rcond %.3g); the left basis is orthonormal.", rcond(M));
            end
            tab_phase.Left = Wl(sub2ind(size(Wl), tab_phase.Index, tab_phase.Kernel));
        end
        c_kernel{i} = struct("rm_right", R, "rm_left", Wl, "sv_state", sv_state, "tab_phase", tab_phase, "n_dim", n_dim, ...
            "s_port", s_port, "s_message", string(s_message));
    end
    sct_kernel = [c_kernel{:}];
end
