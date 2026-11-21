function varargout = eval_workspace(varargin)
% Evaluate code in a workspace of its own: unpack the variables, run the code, pack them back.
%
% The only names used here are varargin and varargout, so the code can use every other name
% without a collision with a variable of this function. An error of the code propagates to
% the caller, which keeps its own copy of the variables.
    arguments (Input, Repeating)
        varargin   % 1: variables by name (struct); 2: code (char).
    end
    arguments (Output, Repeating)
        varargout  % 1: variables after the code (struct); 2: Command Window output of the code (char).
    end
    varargin{3} = fieldnames(varargin{1});
    while ~isempty(varargin{3})
        eval([varargin{3}{1} ' = varargin{1}.(varargin{3}{1});']);
        varargin{3}(1) = [];
    end
    varargout{2} = evalc(varargin{2});
    varargout{1} = struct();
    varargin{3} = setdiff(who, {'varargin', 'varargout'});
    while ~isempty(varargin{3})
        varargout{1}.(varargin{3}{1}) = eval(varargin{3}{1});
        varargin{3}(1) = [];
    end
end
