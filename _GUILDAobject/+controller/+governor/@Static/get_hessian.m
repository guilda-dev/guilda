function sct_hessian = get_hessian(obj, x, V, u)
% Return the energy-function Hessian of the controller: empty blocks (no states).
%
% The Static governor has no states and injects no current: its output Pmech is the constant
% reference, so in the deviation model it adds nothing to the energy function. The blocks
% are Hxx, Hxv, R (0 x 0, 0 x 2), Hvx (2 x 0) and Hvv = zeros(2); PortName is theta and V
% of the bus of the generator. See LocalController.get_hessian for the form.
%
% See also LocalController.get_hessian, Component.get_hessian
    arguments (Input)
        obj
        x (:,1) double = obj.rv_Xequilibrium  % States (none).
        V (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]  % [pu] Voltage [Vre; Vim] of the generator.
        u (:,1) double = obj.rv_Uequilibrium  % Inputs (the reference).
    end
    arguments (Output)
        sct_hessian struct  % Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName.
    end
    sv_port = ["theta";"V"];
    if ~isempty(obj.a_Component) && ~isempty(obj.a_Component.a_Bus)
        sv_port = reshape(string(obj.a_Component.a_Bus.attach_tag(sv_port)), [], 1);
    end
    sct_hessian = struct("Hxx", zeros(0,0), "Hxv", zeros(0,2), "Hvx", zeros(2,0), "Hvv", zeros(2,2), ...
                         "R", zeros(0,0), "StateName", strings(0,1), "PortName", sv_port);
end
