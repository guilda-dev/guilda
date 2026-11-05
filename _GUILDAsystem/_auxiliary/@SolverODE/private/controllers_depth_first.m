function c_LC = controllers_depth_first(parent)
% The local controllers under parent and the controllers nested in them, depth first
% (the order of the state vector, see initialize_index)
    c_LC = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        c_LC = [c_LC; {con}; controllers_depth_first(con)]; %#ok<AGROW>
    end
end
