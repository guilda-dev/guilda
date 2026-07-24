function out = reorder(sys,opt)
    arguments
        sys ss
        opt.method    (1,1) string {mustBeMember(opt.method,   ["VariableNames","ComponentNames"])} = "ComponentNames";
        opt.direction (1,1) string {mustBeMember(opt.direction,[ "ascend" , "descend" , "stable"])} = "ascend";
    end

    switch opt.method
        case "VariableNames"
            sv_x = tools.vcellfun(@(n) extractVar(n), sys.StateName );
            sv_u = tools.vcellfun(@(n) extractVar(n), sys.InputName );
            sv_y = tools.vcellfun(@(n) extractVar(n), sys.OutputName );
        case "ComponentNames"
            sv_x = tools.vcellfun(@(n) extractMac(n), sys.StateName );
            sv_u = tools.vcellfun(@(n) extractMac(n), sys.InputName );
            sv_y = tools.vcellfun(@(n) extractMac(n), sys.OutputName );
    end

    if opt.direction=="stable"
        [ ~, ~, flag_x] = unique(sv_x, "stable");
        [ ~, ~, flag_u] = unique(sv_u, "stable");
        [ ~, ~, flag_y] = unique(sv_y, "stable");
        [ ~, i_x] = sort(flag_x);
        [ ~, i_u] = sort(flag_u);
        [ ~, i_y] = sort(flag_y);
    else
        [ ~, i_x] = sort(sv_x, 1, opt.direction);
        [ ~, i_u] = sort(sv_u, 1, opt.direction);
        [ ~, i_y] = sort(sv_y, 1, opt.direction);
    end

    out = sys(i_y,i_u);
    out.A = out.A(i_x,i_x);
    out.B = out.B(i_x,i_u);
    out.C = out.C(i_y,i_x);
    if ~isempty(sys.E)
        out.E = out.E(i_x,i_x);
    end

    out.StateName = sys.StateName(i_x);
    out.InputGroup = orderfields( out.InputGroup );
    out.OutputGroup = orderfields( out.OutputGroup );
end

function out = extractMac(strName)
    charName = char(strName);
    i_break  = find(charName=='_',1,"last") + 1;
    out = string( charName(i_break:end) );
end

function out = extractVar(strName)
    charName = char(strName);
    i_break  = find(charName=='_',1,"last") - 1;
    out = string( charName(1:i_break) );
end