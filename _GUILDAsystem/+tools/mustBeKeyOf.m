function mustBeKeyOf(Key, category)
% Validate that Key is a model key of the category.
%
% For the arguments blocks of the methods that build a model from its key
% (Bus.add_component, PowerNetwork.add_branch, ...). The keys are those of
% GUILDA.keymap(category); the error lists them.
%
% <@Examples>
% ```matlab
% arguments (Input)
%     Key (1,:) char {tools.mustBeKeyOf(Key, "Component")}
% end
% ```
%
% See also GUILDA.keymap
    arguments (Input)
        Key        % Model key to check (char or string).
        category   (1,1) string   % Model category: "Component", "Branch", "LocalController" or "GlobalController".
    end
    dic = GUILDA.keymap(category);
    if ~(ischar(Key) || isstring(Key)) || ~isscalar(string(Key)) || ~isKey(dic, string(Key))
        error(msg("GUILDA:mustBeKeyOf:UnknownKey", char(category), char(join(keys(dic)', ", "))))
    end
end
