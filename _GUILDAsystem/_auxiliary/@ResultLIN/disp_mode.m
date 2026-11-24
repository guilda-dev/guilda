function varargout = disp_mode(obj, opt)
% Display the modes of the linear model as a table.
%
% Prints the rows of get_mode: one line per mode with its number, the eigenvalue
% (real and imaginary part [1/s]), the frequency [Hz], the damping ratio [%] ("-" for a
% real mode) and the dominant owner (DominantOwner of get_mode), under a title line with
% the network, the Type, the section and the number of modes. MinFrequency > 0 keeps the
% oscillatory modes with a frequency of at least MinFrequency (as in get_mode), and
% MaxFrequency those of at most MaxFrequency.
%
% Index chooses the section (default res.Index; see ResultLIN), and Time, when given, the
% section whose time rv_t is nearest to it; Index "all" shows every section, the blocks
% separated by an empty line. With one output it returns the text instead of displaying it.
%
% On a contribution result (sv_target nonempty, see get_contribution) the numbers are of
% the part alone and have no meaning for the whole system.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().get_sys();
% res.disp_mode()                                   % every mode
% res.disp_mode(MinFrequency=0.1, MaxFrequency=2)   % electromechanical modes
% s = res.disp_mode(Index="all");                   % every section, as text
% ```
%
% See also ResultLIN.get_mode, ResultLIN.disp_summary
    arguments (Input)
        obj
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model whose modes are shown: "ODE" or "DAE"; the Type of the result when omitted.
        opt.MinFrequency (1,1) double {mustBeNonnegative} = 0     % [Hz] Smallest frequency shown; > 0 keeps the oscillatory modes only.
        opt.MaxFrequency (1,1) double {mustBeNonnegative} = Inf   % [Hz] Largest frequency shown.
        opt.Index {mustBeSection} = obj.Index   % Section (1 ... numel(rv_t)) or "all" (every section); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}      % [s] Time: the section whose rv_t is nearest; overrides Index.
    end
    arguments (Output, Repeating)
        varargout  % Text of the table when one output is requested; displayed otherwise.
    end
    iv_sec = section_list(obj, opt);
    n_t = numel(obj.rv_t);
    c_block = cell(1, numel(iv_sec));
    for i = 1:numel(iv_sec)
        k = iv_sec(i);
        tab = obj.get_mode(Type=opt.Type, MinFrequency=opt.MinFrequency, Index=k).tab_mode;
        tab = tab(tab.Frequency <= opt.MaxFrequency, :);
        s_sec = "";
        if n_t > 1
            s_sec = sprintf(", section %d of %d at rv_t = %g", k, n_t, obj.rv_t(k));
        end
        sv = sprintf("Modes of %s (Type %s%s): %d modes", obj.s_network, opt.Type, s_sec, height(tab));
        sv(end+1) = sprintf("%5s  %12s %12s  %10s  %11s  %s", "No.", "Re [1/s]", "Im [1/s]", "Freq [Hz]", "Damping [%]", "Dominant owner"); %#ok<AGROW>
        for j = 1:height(tab)
            s_zeta = "-";
            if ~isnan(tab.DampingRatio(j))
                s_zeta = sprintf("%.2f", 100*tab.DampingRatio(j));
            end
            sv(end+1) = sprintf("%5d  %12.5g %12.5g  %10.4g  %11s  %s", j, real(tab.Eigenvalue(j)), imag(tab.Eigenvalue(j)), ...
                tab.Frequency(j), s_zeta, tab.DominantOwner(j)); %#ok<AGROW>
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
