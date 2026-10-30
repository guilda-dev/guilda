function set_bus(obj,a_Bus)
% Set the end buses of the branch.
%
% Called by PowerNetwork.add_branch with the two buses, and with an empty cell when the branch is removed.
    obj.a_Bus = a_Bus;
end