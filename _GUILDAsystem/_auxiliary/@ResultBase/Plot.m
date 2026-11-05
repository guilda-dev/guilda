function varargout = Plot(obj, varargin) %#ok<STOUT>
% Plot the result.
%
% Plots the result. Each result class defines its own figures and Name-Value
% options. A result class without a plot stops with GUILDA:ResultBase:Unsupported.
    arguments (Input)
        obj
    end
    arguments (Input, Repeating)
        varargin  % Name-Value plot options defined by the result class.
    end
    arguments (Output, Repeating)
        varargout % Created figure or axes (defined by the result class).
    end
    obj.error_unsupported("Plot");
end
