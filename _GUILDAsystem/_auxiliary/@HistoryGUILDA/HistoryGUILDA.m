classdef HistoryGUILDA < auxiliary
% Run log of a GUI: runs code strings in a private workspace and exports them as a script.
%
% Every GUI action is a line of MATLAB code. run evaluates that code string itself, in a
% workspace that belongs to this object, and records it as one entry of tab_entry. The code
% string is the only source of the action, so get_script returns exactly what the GUI ran:
%
% - Variables assigned by the code stay in the workspace for the next runs
%   (`res_pf = net.calculate_powerflow();` makes `res_pf` available). set_variable and
%   get_variable read and write them from outside.
% - Entries are never removed: model edits accumulate. A failed entry stays in the log with
%   its error message but is left out of the script.
% - attach_view draws the log in a container of a uifigure: `[mark] Label → Detail` and the
%   `>> code` lines of each entry, redrawn on the event Changed. A double click on a `>>`
%   line opens the file of the method it calls when it can be found.
%
% The code runs in a private function whose only variables are varargin and varargout: the
% workspace variables are unpacked into it, the code is evaluated with evalc, and every
% variable except varargin and varargout is packed back. So the code can use any variable
% name except varargin and varargout. A failed run does not change the workspace.
%
% <@Examples>
% ```matlab
% h = HistoryGUILDA(Header="Built in the GUI");
% h.run("Model", "New network", "net = PowerNetwork();");
% h.run("Model", "Add a bus", "net.add_bus();");
% disp(h.get_script())
% h.export_script("build_net.m")
% ```
%
% See also DrawerOptionDialog, DrawerModelGUI

    properties(SetAccess = private) % Log
        tab_entry      % One row per run: Group, Label, Code, Status ("run", "done" or "fail"), Detail. <@Type> table
    end
    properties(Access = private) % Workspace
        sct_variable   % Variables of the workspace the code runs in, by name. <@Type> struct
        l_echo         % Print ">> code" and the output of each run in the Command Window. <@Type> logical
        sv_header      % Comment lines at the top of the script. <@Type> string
    end

    events
        Changed  % An entry was added or its status changed.
    end

    methods
        function obj = HistoryGUILDA(opt)
        % Create an empty log with an empty workspace.
            arguments (Input)
                opt.Echo (1,1) logical = false              % Print ">> code" and the output of each run in the Command Window.
                opt.Header (1,:) string = string.empty      % Comment lines at the top of the script ("% " is added when missing).
            end
            arguments (Output)
                obj  % The log.
            end
            obj.tab_entry    = table('Size', [0 5], 'VariableTypes', repmat("string", 1, 5), ...
                'VariableNames', ["Group", "Label", "Code", "Status", "Detail"]);
            obj.sct_variable = struct();
            obj.l_echo       = opt.Echo;
            obj.sv_header    = opt.Header;
        end

        set_variable(obj, s_name, value)
        value = get_variable(obj, s_name)
        [l_ok, s_detail] = run(obj, s_group, s_label, s_code)
        s_script = get_script(obj)
        export_script(obj, s_path)
        h = attach_view(obj, h_container)
    end
end
