function sct = get_option(obj)
% Return Q, R, Input and V0, the constructor arguments outside the dynamics table.
%
% Q and R are the weights as stored (a vector given is its diagonal matrix, empty is the
% identity), Input the inputs as given (empty: all the inputs of the component) and V0 the
% voltage of the infinite bus. The gain K and sys_design are not returned: initialize
% computes them. net.export writes these values to option.json.
%
% See also LocalController.get_option, PowerNetwork.export
    arguments (Input)
        obj
    end
    arguments (Output)
        sct (1,1) struct  % Q, R, Input and V0.
    end
    sct = struct("Q", obj.Q, "R", obj.R, "Input", obj.sv_input, "V0", obj.V0);
end
