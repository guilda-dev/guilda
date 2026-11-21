classdef DrawerModelGUI < auxiliary
% GUI of one model: breadcrumb, class, tag, Docs link, stale state, child tables, parameters and pages.
%
% LayerPackage.launch_gui creates one, in a new uifigure or in a given container (uifigure,
% uipanel, uitab or uigridlayout), so that it can be embedded in another app. The layout
% follows the size of the container:
%
% - Header (logo blue band over a lime line): the breadcrumb from the root to the model,
%   whose links show those models in the same container (render); then the tag, the class,
%   a Docs button that opens the class reference (GUILDA.doc("class", ...)) and the stale
%   state (`sct_stale`: each stale tag with its first message).
% - Add buttons (Tag "add", in the color of the kind) above the child tables: + Bus,
%   + Branch, + Controller (add_global_controller) and + Scenario for a PowerNetwork,
%   + Component for a Bus, + Controller (add_local_controller) for a Component and a
%   LocalController (added to its component), and each event (+ Fault, + Trip,
%   + Open branch, + Offset, + Input) for a Scenario. The tooltip names the method. A
%   button opens the option form of the method (DrawerOptionDialog.ask) and runs the code
%   it returns.
% - Child tables (left column, 300 px): the children of one kind at a time (a drop-down
%   "Bus (14)", "Branch (20)", ...) in a compact table with the columns of
%   DrawerTagPicker.element_table and a search field. A click on a row shows that model in
%   the same container; the context menu "Open in new window" opens it in a new uifigure
%   (with the same history) and "Remove" removes it after a confirmation. Each set of
%   columns has a table of its own (Tag "children" on the one shown). The element tables
%   are kept until the history has a new entry; the kind and the search of a model are
%   kept for its next render. A model with add buttons and no children gets a column as
%   wide as the buttons; a model with neither leaves it to the body.
% - Body (one uihtml, Tag "body", drawn by private/model_body.html from its Data): the tabs
%   Parameter (one editable table per container of a_Parameter, titled by its s_tag; only
%   for a model with a_Parameter, not for a Scenario), then the tables of gui_content. A
%   container of one row whose parameters are all scalars is a vertical Name/Value table
%   (full names), two such tables side by side; any other container is a table with one
%   column per parameter. Every table fits its columns to the header and the contents and
%   scrolls sideways. An edited cell is written as code, e.g.
%   `net.a_Bus{1}.tab_parameter.powerflow.V = 1.02;`; on an error the table goes back to
%   the stored values and an alert shows the message. The rows of the event tables of
%   a Scenario have the context menu "Remove event" (Scenario.remove_event). The tab of
%   the same title stays selected from one model to the next.
%
% A render writes the new model into the components kept from the first render (the body
% gets one Data), so that moving between models stays fast.
%
% Every action is a line of MATLAB code run by the history (HistoryGUILDA.run), so it is
% logged and get_script reproduces it. The code reaches each model from the root variable of
% the history: `net` for a network (e.g. `net.a_Bus{3}.a_Component{1}`), otherwise a name
% of the class of the root (`bus`, `branch`, `comp`, `con`, `gcon`). After an action the GUI
% is drawn again (also after a failed one, which may have changed part of the model), and
% after a successful one the event ModelChanged is notified. Each render that shows another
% model than before (the breadcrumb, a child table, or render called by an app) notifies
% TargetChanged, so that an app can follow the model shown (GUILDA.launch_gui selects it in
% its network diagram). A failed action shows its error
% in an alert (a warning on a hidden figure). Its colors are set on every component, so the
% MATLAB theme does not change them; a new uifigure gets the light theme where uifigure has
% a Theme property (R2025a and later).
%
% The parent, children and pages are protected members of the model, which a class outside
% the model hierarchy cannot read; launch_gui passes `f_model`, made inside LayerPackage, to read them.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% h = net.a_Bus{1}.launch_gui();   % new window
% h.render(net.a_Branch{1});       % show another model in the same window
% disp(h.history.get_script())     % the code of the actions done in the GUI
% ```
%
% See also LayerPackage.launch_gui, LayerPackage.gui_content

    properties(SetAccess = private) % Display
        a_target     % Model shown. <@Type> LayerPackage
        h_container  % Container the GUI fills (uifigure, uipanel, uitab or uigridlayout). <@Type> matlab.ui.container
        history      % Log that runs and records the actions of the GUI as code. <@Type> HistoryGUILDA
    end
    properties(Access = private) % Model access
        f_model      % Reads the parent, children and pages of a model: @(o) struct("parent", "children", "pages"). <@Type> function_handle
        s_root       % Variable of the history that holds the root model, e.g. "net". <@Type> string
        m_cache      % Child tables kept between renders of the same model and element tables kept until the next run (update_navigation). <@Type> containers.Map
        m_ui         % Components kept between renders, by name (build_frame); empty before the first render. <@Type> containers.Map
    end

    events
        ModelChanged   % An action of the GUI changed the model (an add, a remove or a parameter edit).
        TargetChanged  % render showed another model than before (a breadcrumb link, a child table or a call of render).
    end

    methods
        function obj = DrawerModelGUI(a_target, h_container, f_model, history)
        % Create the GUI of a model in a container (a new uifigure when empty).
        %
        % The root model (the end of the parents) is the variable of the history named after
        % its class (net, bus, branch, comp, con, gcon); it is set when the history has none.
            arguments (Input)
                a_target (1,1) LayerPackage    % Model to show (a PowerSystemModel or a Scenario).
                h_container                    % uifigure, uipanel, uitab or uigridlayout; [] opens a new uifigure.
                f_model (1,1) function_handle  % Reader of the parent, children and pages (made by LayerPackage.launch_gui).
                history (1,1) HistoryGUILDA    % Log that runs the actions; its root variable must be the root of a_target.
            end
            arguments (Output)
                obj  % The GUI.
            end
            a_root = a_target;
            a_parent = f_model(a_root).parent;
            while ~isempty(a_parent)
                if iscell(a_parent)
                    a_parent = a_parent{1};
                end
                a_root = a_parent;
                a_parent = f_model(a_root).parent;
            end
            sv_class = ["PowerNetwork", "Bus", "Branch", "Component", "LocalController", "GlobalController"];
            sv_name  = ["net",          "bus", "branch", "comp",      "con",             "gcon"];
            l_class  = arrayfun(@(s) isa(a_root, s), sv_class);
            obj.s_root = "model";
            if any(l_class)
                obj.s_root = sv_name(find(l_class, 1));
            end
            try
                a_variable = history.get_variable(obj.s_root);
            catch    % no root variable yet
                history.set_variable(obj.s_root, a_root);
                a_variable = a_root;
            end
            if ~(isa(a_variable, "handle") && isscalar(a_variable) && a_variable == a_root)
                error(msg("GUILDA:DrawerModelGUI:OtherRoot", obj.s_root, string(a_root.s_tag)))
            end
            if isempty(h_container)
                h_container = uifigure("Name", class(a_target) + " " + string(a_target.s_tag), ...
                    "Color", tools.gui_palette().rv_background);
                if isprop(h_container, "Theme")
                    h_container.Theme = "light";
                end
            elseif ~tools.is_ui_container(h_container)
                error(msg("GUILDA:DrawerModelGUI:NotUIContainer", class(h_container)))
            end
            obj.h_container = h_container;
            obj.f_model     = f_model;
            obj.history     = history;
            obj.m_cache     = containers.Map("KeyType", "char", "ValueType", "any");
            obj.m_ui        = containers.Map("KeyType", "char", "ValueType", "any");
            obj.render(a_target);
        end

        render(obj, a_target)
    end

    methods(Access = private)
        s_expr = model_expression(obj, a_model, a_chain)
        l_ok = run_code(obj, s_label, s_code, opt)
    end
end
