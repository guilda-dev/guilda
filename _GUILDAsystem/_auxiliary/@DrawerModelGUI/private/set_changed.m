function set_changed(h, varargin)
% Set the properties of a component whose values differ from the ones given (name-value pairs).
%
% Every set property of a UI component is sent to the figure, also with the same value;
% writing only the changed ones keeps a render that changes little cheap. Text-like values
% (char, string, on/off) are compared as strings.
    arguments (Input)
        h           % Component.
    end
    arguments (Input, Repeating)
        varargin    % Property name, then its value.
    end
    arguments (Output)
    end
    c_set = {};
    for k = 1:2:numel(varargin)
        s_name = varargin{k};
        value  = varargin{k+1};
        old = h.(s_name);
        if isequal(old, value)
            continue
        end
        if (ischar(old) || isstring(old) || isa(old, "matlab.lang.OnOffSwitchState")) ...
                && (ischar(value) || isstring(value)) && isequal(string(old), string(value))
            continue
        end
        c_set(end+1:end+2) = {s_name, value}; %#ok<AGROW>
    end
    if ~isempty(c_set)
        set(h, c_set{:});
    end
end
