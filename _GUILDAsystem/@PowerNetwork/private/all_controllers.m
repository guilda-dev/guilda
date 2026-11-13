function list = all_controllers(parent)
% Local controllers of parent, depth first (the order of the variable map).
    arguments (Input)
        parent  % Component or local controller.
    end
    arguments (Output)
        list (:,1) cell  % Its local controllers and theirs.
    end
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
