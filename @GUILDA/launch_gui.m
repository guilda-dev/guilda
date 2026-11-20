function h = launch_gui(net)
% Start the GUILDA app: build a network, analyze it and export the session as a script.
%
% The app (DrawerGUILDA) opens in a new window. Every action runs as a line of MATLAB code
% in one run log (HistoryGUILDA) shared by the whole app, so the log shows the code and the
% button "Export script" writes a script that repeats the session.
%
% - Without a network a start screen offers an "Empty network" (`net = PowerNetwork();`), the sample
%   networks of `_GUILDAobject/+network` (`net = network.IEEE14bus();`), a model folder
%   written by net.export (`net = PowerNetwork.import("<path>");`) and a MATPOWER case
%   (`net = PowerNetwork.import_matpower("case14");`). The choice is the first line of the
%   script.
% - With a network the app works on it as `net`; the script header says that net is the
%   network passed at startup.
% - The tab bar across the top switches the right half between Model, Power flow,
%   OPF, CPF, Time simulation and Linearization. The left half shows the
%   network diagram (net.plot_diagram) over the run log; the diagram is drawn again after
%   every run. In Model a click on a bus, branch or component of the diagram shows
%   it in the model GUI (obj.launch_gui), where models are added, removed and edited.
%
% <@Examples>
% ```matlab
% h = GUILDA.launch_gui();                     % start screen
% net = network.IEEE14bus();
% h = GUILDA.launch_gui(net);                  % work on net
% disp(h.history.get_script())                 % the code of the session
% h.history.export_script("my_session.m")      % the same as "Export script"
% ```
%
% See also DrawerGUILDA, HistoryGUILDA, LayerPackage.launch_gui, ResultBase.launch_gui
    arguments (Input)
        net = []  % Network to work on; omitted or [] shows the start screen. <@Type> PowerNetwork
    end
    arguments (Output)
        h DrawerGUILDA  % The app.
    end
    h = DrawerGUILDA(net);
end
