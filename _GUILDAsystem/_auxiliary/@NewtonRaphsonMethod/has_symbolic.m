function l = has_symbolic()
% Return true when Symbolic Math Toolbox is installed and licensed.
    arguments (Output)
        l  % true when Symbolic Math Toolbox is available.
    end
    l = license('test','Symbolic_Toolbox') && ~isempty(ver('symbolic'));
end
