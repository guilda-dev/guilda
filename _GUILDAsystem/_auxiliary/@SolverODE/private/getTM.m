function [sv_tag, rv_rep] = getTM(OBJs, sv_tag, rv_rep)
    if nargin < 2
        sv_tag = [];
        rv_rep = [];
    end

    for no = 1:numel(OBJs)
        OBJ = OBJs{no};
        rs_idx = numel([OBJ.sv_x; OBJ.sv_u]);

        sv_tag = [sv_tag; OBJ.s_tag]; %#ok
        rv_rep = [rv_rep; rs_idx];      %#ok

        % its local controllers, depth first (the order of SolverODE.initialize_index)
        if ~isempty(OBJ.a_LocalController)
            [sv_tag, rv_rep] = getTM(OBJ.a_LocalController, sv_tag, rv_rep);
        end
    end
end
