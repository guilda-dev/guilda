function tab = disp_equations(Key)
% List the equations and the variables of model classes, read from their help.
%
% For each model key, reads the help of its class (tools.read_model_help): the ```math
% blocks of the `**Equations**` section as LaTeX, and the bullets of the
% `**State variables**`, `**Input signals**`, `**Output signals**` and `**Parameters**`
% sections (name, unit, description). The equations are those written in the help, not
% derived from the code, so they also cover models with if/switch. The keys are those of
% GUILDA.keymap for Component, Branch, LocalController and GlobalController.
%
% Without an output, prints each class with a [doc] link to its reference page, the
% lines of its Equations section (or "no equations in the help") and its variables.
% With an output, returns the table and prints nothing.
%
% <@Examples>
% ```matlab
% GUILDA.disp_equations("gen-classical")             % print one class
% tab = GUILDA.disp_equations(["avr-ST1","pss-PSS1"]);
% tab.Equations{1}                                   % LaTeX blocks of avr-ST1
% tab.Variables{1}                                   % Kind, Name, Unit, Description
% tab = GUILDA.disp_equations();                     % every model key
% ```
%
% See also tools.read_model_help, Component.disp_io, LocalController.disp_io, GUILDA.keymap
    arguments (Input)
        Key (:,1) string {mustBeModelKey} = all_keys()  % Model keys (default: every key of the four categories).
    end
    arguments (Output)
        tab  % Table, one row per key: Key, Class, Equations (cell of string columns, one LaTeX block per element), Variables (cell of tables Kind, Name, Unit, Description).
    end
    dic = key_class();
    n = numel(Key);
    sv_class = dic(Key);
    c_eq  = cell(n,1);
    c_var = cell(n,1);
    c_txt = cell(n,1);
    for k = 1:n
        sct = tools.read_model_help(sv_class(k));
        c_eq{k}  = sct.Equations;
        c_var{k} = sct.Variables;
        c_txt{k} = sct.Text;
    end
    % the column Variables replaces the default dimension name "Variables" (tab.Variables is the column)
    tab_out = table(Key, sv_class, c_eq, c_var, 'VariableNames', ["Key","Class","Equations","Variables"], ...
                    'DimensionNames', ["Row","Data"]);
    if nargout > 0
        tab = tab_out;
        return
    end

    bar = repmat('=', 1, 80);
    for k = 1:n
        disp(bar)
        fprintf('%s  <a href="matlab:GUILDA.doc(''class'', ''%s'')">[doc]</a>  %s\n', ...
            Key(k), sv_class(k), sv_class(k))
        disp(bar)
        disp("Equations")
        if isempty(c_eq{k})
            disp("  no equations in the help")
        else
            fprintf('  %s\n', c_txt{k})
        end
        tv = c_var{k};
        if height(tv) > 0
            disp("Variables")
            n_name = max(strlength(tv.Name));
            for i = 1:height(tv)
                s_unit = "";
                if tv.Unit(i) ~= ""
                    s_unit = "[" + tv.Unit(i) + "]";
                end
                fprintf('  %-4s  %-*s  %-6s  %s\n', tv.Kind(i), n_name, tv.Name(i), s_unit, tv.Description(i))
            end
        end
        disp(" ")
    end
end


function dic = key_class()
    % Model key -> class name, over the four categories
    dic = dictionary(string.empty, string.empty);
    for s_cat = ["Component","Branch","LocalController","GlobalController"]
        d = GUILDA.keymap(s_cat);
        dic(keys(d)) = values(d);
    end
end

function sv = all_keys()
    sv = reshape(keys(key_class()), [], 1);
end

function mustBeModelKey(Key)
    % A model key of one of the four categories
    mustBeMember(Key, all_keys())
end
