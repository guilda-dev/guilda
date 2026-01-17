function [Ymat, GB] = get_admittance_matrix(obj, ivec_bus, ivec_branch)
    arguments
        obj 
        ivec_bus    (1,:) double {mustBeInteger(ivec_bus   ),mustBePositive(ivec_bus  )} = 1:numel(obj.Buses);
        ivec_branch (1,:) double {mustBeInteger(ivec_branch),mustBePositive(ivec_branch)} = 1:numel(obj.Branches);
    end

    n_bus = numel(obj.a_bus);
    Y     = zeros(n_bus, n_bus);
    shunt = tools.dcellfun(@(b) b.shunt, obj.Buses(ivec_bus));
    

    for i = ivec_branch
        br      = obj.Branches{i};
        ivec_rc = [br.from,br.to];
        if all( ismember(ivec_rc, ivec_bus) )
            Yij = br.get_admittance_matrix();
            Y(ivec_rc,ivec_rc) = Y(ivec_rc,ivec_rc) + Yij;
        end
    end
    
    
    Ymat = sparse( Y+shunt );
    if nargout == 2
        GB = tools.complex2matrix(Ymat);
    end
end