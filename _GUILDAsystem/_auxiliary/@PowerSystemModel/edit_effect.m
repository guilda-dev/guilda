function [lv_odefcn, lv_equilibrium] = edit_effect(obj, sv_tag, sv_log)
% What each edit-log row makes stale, from its tag and log (one edit in handle_edit,
% the rows of the network in PowerNetwork.l_staleEquilibrium, check_edit and
% initialize).
%   tag                    f_* handles   equilibrium
%   Parameter(dynamics)    stale         stale
%   Parameter(base)        -             stale     (PowerNetwork para_base: baseMVA;
%                                                   no model handle holds it)
%   Parameter(base), Hz    -             -         (log "edit Hz": PowerNetwork.handle_edit
%                                                   marks the handles of every layer; the
%                                                   equilibrium does not depend on the
%                                                   nominal frequency)
%   Parameter(powerflow)   -             stale
%   Topology               -             stale     (add_/remove_/replace_)
%   Slack                  -             stale
%   Initialize             -             stale     (initialize is writing the equilibrium;
%                                                   the row is cleared when it finishes)
%   Parameter(operation)   -             -
%   Parameter(OPF)         -             -
%   Parameter(graph)       -             -
%   OPF                    -             -         (set_opffcn / reset_opffcn)
%   Tag                    -             -         (rename through s_tag)
    arguments (Input)
        obj            % Any layer (the mapping does not depend on it).
        sv_tag string  % Tags of the rows (Nx1).
        sv_log string  % Log messages of the rows (Nx1).
    end
    arguments (Output)
        lv_odefcn      % True for rows that make the handles of the parameter's owner stale (Nx1).
        lv_equilibrium % True for rows that make the equilibrium stale (Nx1).
    end
    lv_odefcn      = sv_tag == "Parameter(dynamics)";
    lv_equilibrium = matches(sv_tag, ["Parameter(dynamics)", "Parameter(powerflow)", "Topology", "Slack", "Initialize"]) ...
                   | (sv_tag == "Parameter(base)" & sv_log ~= "edit Hz");
end
