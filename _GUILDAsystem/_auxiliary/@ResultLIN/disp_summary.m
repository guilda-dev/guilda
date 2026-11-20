function varargout = disp_summary(obj, opt)
% Display a summary of the linearization result.
%
% Shows one block per section: a title line with the network, the layer, the section and
% whether it is usable (output.lv_flag), and one bullet per item:
%
% - Model: the Type and Port of the result (a port model for a layer other than the
%   network), the point (the equilibrium, a given point, or the section at its rv_t: the
%   time of {sim, rv_t}, the column of a matrix of points) and the Form.
% - Energy function (Form "hessian" available): the asymmetry rv_asymmetry of the bus
%   block of the section, 0 for a lossless model.
% - Size: the numbers of states n_x, bus variables n_v and inputs n_u.
% - Status: the issue of the section (output.sv_issue, "none" when usable) and the
%   reciprocal condition number of Avv (output.rv_rcond_Avv); then its message, if any.
% - Modes: the largest real part of the eigenvalues of get_eigenvalue(Type), the number of
%   unstable modes (real part above 1e-6) and of zero modes (|lambda| up to
%   1e-6*max(1, max|lambda|), as in get_mode); "not available" with the reason when the
%   model of the Type cannot be made.
% - Kernel: the dimension of the kernel of the Jacobian of the DAE (get_kernel: one
%   rotation per island), for the network.
%
% Index chooses the section (default res.Index; see ResultLIN); Index "all" shows every
% section, the blocks separated by an empty line. It reads only the stored result. With
% one output it returns the text instead of displaying it.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().get_sys();
% res.disp_summary()
% s = res.disp_summary(Index="all");   % every section, as text
% ```
%
% See also ResultLIN.disp_mode, ResultLIN.get_eigenvalue, ResultLIN.get_kernel, ResultPF.disp_summary
    arguments (Input)
        obj
        opt.Index {mustBeSection} = obj.Index   % Section (1 ... numel(rv_t)) or "all" (every section); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}      % [s] Time: the section whose rv_t is nearest; overrides Index.
    end
    arguments (Output, Repeating)
        varargout  % Summary text when one output is requested; displayed otherwise.
    end
    iv_sec = section_list(obj, opt);
    n_t = numel(obj.rv_t);
    l_net = isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork";
    s_layer = "";
    if isfield(obj.output, "s_layer")
        s_layer = obj.output.s_layer;
    end
    tab = obj.tab_variable;
    c_block = cell(1, numel(iv_sec));
    for i = 1:numel(iv_sec)
        k = iv_sec(i);
        s_sec = "";
        if n_t > 1
            s_sec = sprintf(", section %d of %d", k, n_t);
        end
        s_state = "not usable";
        if obj.output.lv_flag(k)
            s_state = "usable";
        end
        sv = "Linearization of " + obj.s_network + " (layer " + s_layer + s_sec + "): " + s_state;

        s_point = "a given point";
        if isfield(obj.output, "l_equilibrium") && obj.output.l_equilibrium
            s_point = "the equilibrium";
        elseif ~isnan(obj.rv_t(k))
            s_point = sprintf("of the section at rv_t = %g", obj.rv_t(k));
        end
        if l_net
            s_port = "PQ";
            if isfield(obj.options, "Port")
                s_port = obj.options.Port;
            end
            sv(end+1) = "- Model: Type " + obj.Type + ", Port " + s_port + ", point " + s_point + ", Form " + obj.Form; %#ok<AGROW>
        else
            sv(end+1) = "- Model: port model of the layer, point " + s_point + ", Form " + obj.Form; %#ok<AGROW>
        end
        if ~isnan(obj.rv_asymmetry(k))
            sv(end+1) = sprintf("- Energy function: asymmetry %.3g of the bus block Hvv + Hvv_net (0 when lossless)", obj.rv_asymmetry(k)); %#ok<AGROW>
        end
        n_v = 0;
        if isfield(obj.c_section{k}, "n_v")
            n_v = obj.c_section{k}.n_v;
        end
        sv(end+1) = sprintf("- Size: n_x = %d states, n_v = %d bus variables, n_u = %d inputs", ...
            nnz(tab.Kind == "x"), n_v, nnz(tab.Kind == "u")); %#ok<AGROW>
        s_issue = obj.output.sv_issue(k);
        if s_issue == ""
            s_issue = "none";
        end
        s_rcond = "-";
        if isfield(obj.output, "rv_rcond_Avv") && ~isnan(obj.output.rv_rcond_Avv(k))
            s_rcond = sprintf("%.3g", obj.output.rv_rcond_Avv(k));
        end
        sv(end+1) = "- Status: issue " + s_issue + ", rcond(Avv) " + s_rcond; %#ok<AGROW>
        if strip(obj.output.sv_message(k)) ~= ""
            sv(end+1) = "- Message: " + strip(obj.output.sv_message(k)); %#ok<AGROW>
        end
        try
            cv_lam = obj.get_eigenvalue(obj.Type, Index=k);
            r_max = max([real(cv_lam); -Inf]);
            n_zero = nnz(abs(cv_lam) <= 1e-6*max([1; abs(cv_lam)]));
            sv(end+1) = sprintf("- Modes (%s): %d eigenvalues, largest real part %.4g 1/s, %d unstable, %d zero", ...
                obj.Type, numel(cv_lam), r_max, nnz(real(cv_lam) > 1e-6), n_zero); %#ok<AGROW>
        catch ME
            sv(end+1) = "- Modes (" + obj.Type + "): not available (" + strip(string(ME.message)) + ")"; %#ok<AGROW>
        end
        if l_net
            try
                sct_k = obj.get_kernel(Index=k);
                sv(end+1) = sprintf("- Kernel: dimension %d", sct_k.n_dim); %#ok<AGROW>
            catch ME
                sv(end+1) = "- Kernel: not available (" + strip(string(ME.message)) + ")"; %#ok<AGROW>
            end
        end
        c_block{i} = join(sv, newline);
    end
    s_text = join([c_block{:}], string(newline) + newline);
    if nargout == 1
        varargout = {s_text};
    else
        disp(s_text)
    end
end
