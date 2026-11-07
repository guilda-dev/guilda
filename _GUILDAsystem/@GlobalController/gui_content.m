function sct_page = gui_content(obj)
% Pages of the GUI (gui): the Equilibrium table, then the pages of PowerSystemModel.
%
% - "Equilibrium" ("table"): columns Kind, Name and Value, one row per state
%   (`rv_Xequilibrium`) and per input (`rv_Uequilibrium`). Names are `sv_x` and `sv_u`;
%   when their number differs from that of the values (an input per unit), they are
%   numbered x1, x2, ... and u1, u2, .... Value is text.
%   No rows before the equilibrium is computed; the header shows whether it is stale.
%
% See also PowerSystemModel.gui_content
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_page (:,1) struct  % Pages: fields s_title, s_type, content, s_label.
    end
    rv_X = obj.rv_Xequilibrium(:);
    rv_U = obj.rv_Uequilibrium(:);
    sv_x = obj.sv_x(:);
    sv_u = obj.sv_u(:);
    if numel(sv_x) ~= numel(rv_X)
        sv_x = "x" + string((1:numel(rv_X)).');
    end
    if numel(sv_u) ~= numel(rv_U)
        sv_u = "u" + string((1:numel(rv_U)).');
    end
    sv_kind  = [repmat("State",numel(rv_X),1); repmat("Input",numel(rv_U),1)];
    sv_name  = [sv_x; sv_u];
    sv_value = compose("%.6g", [rv_X; rv_U]);
    tab_eq   = table(sv_kind, sv_name, sv_value, 'VariableNames', ["Kind","Name","Value"]);
    sct_page = struct("s_title","Equilibrium", "s_type","table", "content",tab_eq, "s_label","");
    sct_page = [sct_page; gui_content@PowerSystemModel(obj)];
end
