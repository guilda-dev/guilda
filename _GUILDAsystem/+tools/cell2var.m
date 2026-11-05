function varargout = cell2var(in)
% Distribute the elements of a cell array to separate outputs.
    arguments (Input)
        in         % Cell array to distribute.
    end
    arguments (Output, Repeating)
        varargout  % Element in{k} as output k.
    end
varargout = in;
end
