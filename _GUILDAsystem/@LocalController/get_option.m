function sct = get_option(obj)
% Return the constructor arguments that are not columns of the dynamics table.
%
% net.export writes them to local_controller/<key>/option.json and PowerNetwork.import
% passes them back to the constructor with the row of the table. A constructor argument
% of a controller class is either a column of tab_parameter.dynamics (of the same name) or
% a field of get_option; any other value is not saved. The base class has none (an empty
% struct); a class with such arguments (e.g. controller.local_LQR) overrides it.
%
% See also PowerNetwork.export, PowerNetwork.import
    arguments (Input)
        obj
    end
    arguments (Output)
        sct (1,1) struct  % Name=Value of the constructor arguments outside the table.
    end
    sct = struct();
end
