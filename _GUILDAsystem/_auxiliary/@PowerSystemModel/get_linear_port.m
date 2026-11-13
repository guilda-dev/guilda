function sct_port = get_linear_port(obj) %#ok<STOUT>
% Get the inputs and outputs of the linear model of the layer (port of get_sys).
%
% Each layer with a linear model (PowerNetwork, Bus, Component, LocalController,
% GlobalController) overrides it and returns a struct with the fields
%
% - `sv_input`: Labels of the external inputs, in the order of the inputs of the model.
%   An external input adds to the sum of the sources of the input of that name.
% - `sv_output`: Labels of the outputs: outputs or states of the blocks, bus voltages, or
%   bus currents (tab_bus).
% - `sv_algebraic`: Labels of the bus voltages that are algebraic variables of the model
%   (Vre, Vim of each bus); empty when the voltages are external inputs.
% - `cm_Y`: admittance matrix (complex) of the buses of sv_algebraic (empty without them).
% - `tab_bus`: one row per bus of the layer, columns Bus, Vre, Vim, Ire, Iim (Labels of
%   the voltage and of the current of the bus).
%
% The layers without a linear model (Branch) stop with the error
% GUILDA:PowerSystemModel:NoLinearModel. get_sys calls it.
%
% See also PowerSystemModel.get_sys, SolverLIN.solve
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_port struct   % Fields sv_input, sv_output, sv_algebraic, cm_Y, tab_bus.
    end
    error(msg("GUILDA:PowerSystemModel:NoLinearModel", class(obj), char(string(obj.s_tag))))
end
