function sct = get_option(obj)
% Return Q and R, the constructor arguments outside the dynamics table.
%
% The weights as stored: a vector given is its diagonal matrix, and empty is the default
% (it stays empty). The gain K, sys_design, the state names and the equilibrium are not
% returned: they follow from the generator when initialize runs. net.export writes these
% values to option.json.
%
% See also LocalController.get_option, PowerNetwork.export
    arguments (Input)
        obj
    end
    arguments (Output)
        sct (1,1) struct  % Q and R.
    end
    sct = struct("Q", obj.Q, "R", obj.R);
end
