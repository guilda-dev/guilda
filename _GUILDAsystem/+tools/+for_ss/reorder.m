function out = reorder(sys,opt)
    arguments
        sys ss
        opt.method    (1,1) string {mustBeMember(opt.method,   ["VariableNames","ComponentNames"])} = "ComponentNames";
        opt.direction (1,1) string {mustBeMember(opt.direction,[ "ascend" , "descend" , "stable"])} = "ascend";
    end

    switch opt.method
        case "VariableNames"
            str_x = tools.vcellfun(@(n) extractVar(n), sys.StateName );
            str_u = tools.vcellfun(@(n) extractVar(n), sys.InputName );
            str_y = tools.vcellfun(@(n) extractVar(n), sys.OutputName );
        case "ComponentNames"
            str_x = tools.vcellfun(@(n) extractMac(n), sys.StateName );
            str_u = tools.vcellfun(@(n) extractMac(n), sys.InputName );
            str_y = tools.vcellfun(@(n) extractMac(n), sys.OutputName );
    end

    if opt.direction=="stable"
        [ ~, ~, flag_x] = unique(str_x, "stable");
        [ ~, ~, flag_u] = unique(str_u, "stable");
        [ ~, ~, flag_y] = unique(str_y, "stable");
        [ ~, i_x] = sort(flag_x);
        [ ~, i_u] = sort(flag_u);
        [ ~, i_y] = sort(flag_y);
    else
        [ ~, i_x] = sort(str_x, 1, opt.direction);
        [ ~, i_u] = sort(str_u, 1, opt.direction);
        [ ~, i_y] = sort(str_y, 1, opt.direction);
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