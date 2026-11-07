function sct_page = gui_content(obj)
% Pages of the GUI (gui): the Equilibrium table, then the pages of PowerSystemModel.
%
% - "Equilibrium" ("table"): columns Kind, Name and Value, one row per state (`sv_x`,
%   `rv_Xequilibrium`), per input (`sv_u`, `rv_Uequilibrium`), then the voltage
%   `c_Vequilibrium` and the current `c_Iequilibrium` of the parent. Value is text
%   (complex as a+bj).
%   No rows before the equilibrium is computed; the header shows whether it is stale.
%
% See also PowerSystemModel.gui_content
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_page (:,1) struct  % Pages: fields s_title, s_type and content.
    end
    rv_X = obj.rv_Xequilibrium(:);
    rv_U = obj.rv_Uequilibrium(:);
    c_V  = obj.c_Vequilibrium;
    c_I  = obj.c_Iequilibrium;
    if isempty(rv_X) && isempty(rv_U)
        sv_kind  = strings(0,1);
        sv_name  = strings(0,1);
        sv_value = strings(0,1);
    else
        cv_VI    = [reshape(c_V,[],1); reshape(c_I,[],1)];
        sv_kind  = [repmat("State",numel(rv_X),1); repmat("Input",numel(rv_U),1); ...
                    repmat("Voltage",numel(c_V),1); repmat("Current",numel(c_I),1)];
        sv_name  = [obj.sv_x(:); obj.sv_u(:); repmat("V",numel(c_V),1); repmat("I",numel(c_I),1)];
        sv_value = [compose("%.6g", [rv_X; rv_U]); ...
                    compose("%.6g%+.6gj", real(cv_VI), imag(cv_VI))];
    end
    tab_eq   = table(sv_kind, sv_name, sv_value, 'VariableNames', ["Kind","Name","Value"]);
    sct_page = struct("s_title","Equilibrium", "s_type","table", "content",tab_eq);
    sct_page = [sct_page; gui_content@PowerSystemModel(obj)];
end
