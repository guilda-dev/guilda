function show_msg(s_level, ID, varargin)
% Show a GUILDA warning or INFO message unless the Message setting hides it.
%
% The text is msg(ID, varargin{:}); the caller of show_msg must be allowed to use the ID
% (see msg). "warning" raises a warning with the identifier ID, so it can also be turned off
% with warning("off", ID). "info" prints "INFO: " and the text. Nothing is shown when
% Message.ShowWarning or Message.ShowInfo is false (GUILDA.setting). Errors do not use
% show_msg.
%
% See also msg, GUILDA.setting
%
% <@Examples>
% Inside a method of PowerNetwork:
% ```matlab
% show_msg("warning", "GUILDA:PowerNetwork:NetworkIsland", string(obj), "2", s_island)
% ```
    arguments (Input)
        s_level  (1,1) string {mustBeMember(s_level, ["warning","info"])}  % Kind of message: "warning" or "info".
        ID       % "GUILDA:<Object>:<Key>" (string or char), as in msg.
    end
    arguments (Input, Repeating)
        varargin  % Values for the placeholders of the message, as in msg.
    end

    switch s_level
        case "warning"
            if ~GUILDA.config("Message", "ShowWarning")
                return
            end
            warning(char(ID), "%s", msg(ID, varargin{:}))
        case "info"
            if ~GUILDA.config("Message", "ShowInfo")
                return
            end
            disp("INFO: " + string(msg(ID, varargin{:})))
    end
end
