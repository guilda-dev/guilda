classdef DrawerOptionDialog < auxiliary
% Option form of one method, generated from functionSignatures.json, that writes the call as code.
%
% The form has one row per input of the method in `_GUILDAsystem/resources/functionSignatures.json`
% (or, for a method missing there, `_GUILDAsystem/_auxiliary/resources/functionSignatures.json`)
% (GUILDA.update_keymap(Signature=true) writes it from the arguments blocks), except obj and
% the inputs in Exclude.
%
% Layout (`_GUILDAsystem/resources/gui_forms.json`): the required and positional inputs come
% first, then the main options, then collapsible groups, closed when the form opens (e.g.
% "Limits", "OPF", "Graph", "Advanced"). The entry of a signature lists its main options and
% its groups with their members in order; options it does not list go to "Advanced". It can
% also give English labels and units (`labels`), show options only for some values of another
% option (`visible`, e.g. the OPF options of initialize only for Method="OPF"), and name the
% class whose property defaults are the defaults of options built from its properties
% (`propertyDefaults`, for `opt.?GraphNetDiagram`). A signature missing from the file is
% grouped by the names of its options (`_fallback`: OPF*, Stability*, the limits Pmin/Vmax/...,
% the graph layout names DX/DY/Shape/Path/Offset/MarkerSize/Color, Parent/PlotFcn/Format);
% every other option is a main option. The fields of a group are created when it is opened
% first, so a large form opens fast. An option hidden by `visible` is left out of the call.
%
% The field of an input follows its "type":
%
% - `choices=<expression>`: a dropdown of the values of the expression. An expression on
%   `obj` is evaluated on the object of the call when the History that holds it is given.
%   Tags of the elements of a network (`obj.a_Bus`, `a_Branch`, `a_Component`,
%   `a_LocalController`, `a_GlobalController`, `a_Scenario`) get a text field with the tags
%   (`B001, B002`; commas, spaces or `|` separate them) and a "Select..." button that opens
%   DrawerTagPicker.pick with one row per element (an input whose type has "scalar" keeps its
%   dropdown next to the button and takes one tag). Other tag lists of the object give a list
%   in which several can be selected. A default of several values (`Default:
%   ["Bus","Component","Branch"]`) also gives such a list. Without History, or when the
%   expression cannot be evaluated, it gives a text field.
%   Choices that refer to another input of the method, by its name
%   (`obj.a_PowerNetwork.get_element(unit).sv_u` of Scenario.add_input) or by its default when
%   that is a property of the object (`obj.s_unit`, the default of Unit of EventInput.edit),
%   are evaluated for the current value of that input, and again only when it changes: the
%   dropdown or list takes the new items and keeps the values still among them. While that
%   input is empty or cannot be read, it has no items and the hint "Select unit first".
% - a model key (`choices=...GUILDA.keymap("Component")...`): the dropdown of the keys and a
%   "Select..." button with the key table (DrawerTagPicker.key_table).
% - `logical`: a checkbox; a dropdown of "", "true" and "false" when the default is written
%   in words, where "" leaves the option out.
% - a numeric class: a text field for a number or a numeric array (`[0.1 0.02]`).
% - `string` or `char`: a text field, written as a string literal.
% - anything else (table, cell, struct, function handle, no class): a field for a MATLAB
%   expression, inserted into the code as it is.
%
% Every field shows its default value (the `Default: <expression>.` at the end of the
% purpose, evaluated, on the object of the call too: a default from GUILDA.config shows the
% current setting; `Default: obj.s_status` shows the value of the object). Special numbers
% are shown in words: NaN as "auto" (as "none" when the purpose says that NaN means none,
% e.g. "NaN for none"), Inf and -Inf as "none" when the purpose says so ("Inf: none"), else
% as Inf and -Inf; "" as an empty field. The field takes these words back. A default written
% in words (e.g. "the Solver of the analysis that Method runs") leaves the field empty with
% a muted hint beside it. A default of alternatives of which one refers to another input
% (`Default: From.Time, else [0, 10].` of PowerNetwork.add_scenario) shows the first that
% evaluates for the current value of that input, and follows it while the field is unchanged:
% [0 10] while From is empty, the Time of From when From is a variable of the History
% followed only by properties and numeric indices (`sc`, `net.a_Scenario{2}`; nothing else is
% evaluated, so no method runs), else an empty field with the words as its hint. Left as
% shown, the option is not written (`sc = net.add_scenario();`). The unit of a purpose that
% starts with `[pu]` is shown after the label. A field changed from its default is
% highlighted and gets a reset button (↺). The tooltip is the purpose.
%
% Value gives initial values by input name, written as MATLAB code text (`"B003"`, `0.5`,
% `true`, `["B001", "B002"]`): the field shows them instead of the default. The call still
% compares with the default, so an option given this way is written while it differs from
% the default and left out when it equals it; a required input is always written.
%
% get_code writes the call: the output variables, the object, the required inputs in order,
% then only the visible options whose value differs from the default. An invalid value shows
% a message in the form and get_code returns "", so no callback throws an error.
%
% Picker: the tables are built when "Select..." is pressed, from the network of the call
% (the root variable of Object when it is a network, else the network of the object), and
% only the elements that the choices list are shown. The local controllers of
% Component.remove_local_controller are those of the component of the call, so their tags
% are unique there. A trip (Scenario.add_trip, EventTrip.edit) names its units by tag only:
% when a tag chosen names several elements of the network, the form says so.
%
% <@Examples>
% ```matlab
% fig = uifigure();
% dlg = DrawerOptionDialog("Bus.add_component", fig, Object="net.a_Bus{3}", Output="comp");
% s_code = dlg.get_code()   % comp = net.a_Bus{3}.add_component("gen-park");  (first key)
% dlg = DrawerOptionDialog("PowerNetwork.simulate", fig, Object="net", Output="res", Value=struct("s_scenario", """case1"""));
% s_code = dlg.get_code()   % res = net.simulate("case1");
% s_code = DrawerOptionDialog.ask(fig, "PowerNetwork.calculate_powerflow", Object="net", Output="res_pf");
% h = HistoryGUILDA();
% h.set_variable("net", network.IEEE9bus());
% s_code = DrawerOptionDialog.ask(fig, "PowerNetwork.remove_bus", Object="net", History=h);   % bus tags, with Select...
% ```
%
% See also HistoryGUILDA, DrawerTagPicker, GUILDA.update_keymap, GUILDA.config

    properties(Access = private) % Form
        s_signature  % Method, e.g. "Bus.add_component". <@Type> string
        s_object     % Object expression of the call, e.g. "net.a_Bus{3}". <@Type> string
        sv_output    % Output variables of the call ("" for none). <@Type> string
        sct_field    % One element per field: input, widget, default, display, group, row and handles (see build_form). <@Type> struct
        sct_group    % One element per group: name, header button, open, fields. <@Type> struct
        c_visible    % Conditions of gui_forms.json "visible": struct of names and when. <@Type> cell
        h_grid       % Grid of the form. <@Type> matlab.ui.container.GridLayout
        h_message    % Label of the message of an invalid value. <@Type> matlab.ui.control.Label
        a_object     % Object of the call, or [] without History.
        a_network    % Network the pickers list the elements of, or []. <@Type> PowerNetwork
        a_history    % HistoryGUILDA of the call, or [], to read the variable in an expression field that other fields refer to.
        f_resize     % Called with the height of the form after it changes (set by ask), or [].
    end

    methods
        function obj = DrawerOptionDialog(s_signature, h_container, opt)
        % Create the option form of a method in a container of a uifigure.
            arguments (Input)
                s_signature (1,1) string          % Method in functionSignatures.json, e.g. "Bus.add_component".
                h_container                       % uifigure, uipanel, uitab or uigridlayout of a uifigure.
                opt.Object  (1,1) string          % Object expression of the call, e.g. "net.a_Bus{3}".
                opt.Output  (1,:) string = ""     % Output variables of the call, e.g. "res_pf" ("" for none).
                opt.Exclude (1,:) string = string.empty  % Inputs left out of the form, e.g. "Parent".
                opt.History (1,1) HistoryGUILDA   % Log whose workspace holds the root variable of Object, to evaluate the choices and defaults on the object.
                opt.Value   (1,1) struct = struct()   % Initial values by input name, as MATLAB code text, e.g. struct("s_scenario", """case1""").
            end
            arguments (Output)
                obj  % The form.
            end
            if ~isfield(opt, "Object")
                error(msg("GUILDA:DrawerOptionDialog:NoObject", s_signature))
            end
            if ~tools.is_ui_container(h_container)
                error(msg("GUILDA:DrawerOptionDialog:NotUIContainer", class(h_container)))
            end
            obj.s_signature = s_signature;
            obj.s_object    = opt.Object;
            obj.sv_output   = opt.Output(opt.Output ~= "");
            history = [];
            if isfield(opt, "History")
                history = opt.History;
            end
            obj.build_form(h_container, opt.Exclude, history, opt.Value);
        end

        s_code = get_code(obj)
    end

    methods(Access = private)
        build_form(obj, h_container, sv_exclude, history, sct_value)
        draw_field(obj, k)
        form_event(obj, s_event, k)
    end

    methods(Static)
        s_code = ask(h_parent_figure, s_signature, opt)
    end
end
