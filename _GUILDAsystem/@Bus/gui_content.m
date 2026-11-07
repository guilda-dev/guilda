function sct_page = gui_content(obj)
% Pages of the GUI of a bus: "Equilibrium", then the pages of PowerSystemModel.
%
% "Equilibrium" ("table") has the columns Name and Value, with Value as display text:
%
% - Type: power-flow type (`s_bustype`).
% - V, |V|, ∠V [rad]: voltage phasor at the equilibrium (`c_Vequilibrium`) as a+bj, its
%   magnitude and its angle.
% - I: current injection at the equilibrium (`c_Iequilibrium`) as a+bj.
%
% See also PowerSystemModel.gui, PowerSystemModel.gui_content
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_page (:,1) struct  % Pages: fields s_title, s_type, content, s_label.
    end
    c_V = obj.c_Vequilibrium;
    c_I = obj.c_Iequilibrium;
    Name  = ["Type"; "V"; "|V|"; "∠V [rad]"; "I"];
    Value = [string(obj.s_bustype); ...
        compose("%.6g%+.6gj", real(c_V), imag(c_V)); ...
        compose("%.6g", abs(c_V)); ...
        compose("%.6g", angle(c_V)); ...
        compose("%.6g%+.6gj", real(c_I), imag(c_I))];
    sct_page = [struct("s_title","Equilibrium", "s_type","table", "content",table(Name, Value), "s_label",""); ...
        gui_content@PowerSystemModel(obj)];
end
