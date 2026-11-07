classdef DrawerModelGUI < auxiliary
% GUI of one model: class, tag, stale state, parameter tables and layer tree.
%
% PowerSystemModel.gui creates one, in a new uifigure or in a given container (uifigure,
% uipanel, uitab or uigridlayout), so that it can be embedded in another app. The layout
% follows the size of the container:
%
% - Header: class, tag and the stale state (`sct_stale`: each stale tag with its first
%   message).
% - Tree: the parent, the model (selected) and its children, without the Parameter
%   containers. A click on a node shows that model in the same container (render); the
%   context menu "Open in new window" opens it in a new uifigure.
% - Tabs: Parameter (one editable table per container of a_Parameter, titled by its
%   s_tag), then the pages of gui_content. An edited cell writes the whole table to
%   tab_parameter of its container, which checks and logs it; on an error the table goes
%   back to the stored values and an alert shows the message.
%
% The parent, children and pages are protected members of the model, which a class outside
% the model hierarchy cannot read; gui passes `f_model`, made inside PowerSystemModel, to read them.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% h = net.a_Bus{1}.gui();          % new window
% h.render(net.a_Branch{1});       % show another model in the same window
% ```
%
% See also PowerSystemModel.gui, PowerSystemModel.gui_content

    properties(SetAccess = private) % Display
        a_target     % Model shown. <@Type> PowerSystemModel
        h_container  % Container the GUI fills (uifigure, uipanel, uitab or uigridlayout). <@Type> matlab.ui.container
    end
    properties(Access = private) % Model access
        f_model      % Reads the parent, children and pages of a model: @(o) struct("parent", "children", "pages"). <@Type> function_handle
    end

    methods
        function obj = DrawerModelGUI(a_target, h_container, f_model)
        % Create the GUI of a model in a container (a new uifigure when empty).
            arguments (Input)
                a_target (1,1) PowerSystemModel  % Model to show.
                h_container                      % uifigure, uipanel, uitab or uigridlayout; [] opens a new uifigure.
                f_model (1,1) function_handle    % Reader of the parent, children and pages (made by PowerSystemModel.gui).
            end
            arguments (Output)
                obj  % The GUI.
            end
            if isempty(h_container)
                h_container = uifigure("Name", class(a_target) + " " + string(a_target.s_tag));
            elseif ~is_ui_container(h_container)
                error(msg("GUILDA:DrawerModelGUI:NotUIContainer", class(h_container)))
            end
            obj.h_container = h_container;
            obj.f_model     = f_model;
            obj.render(a_target);
        end

        render(obj, a_target)
    end
end
