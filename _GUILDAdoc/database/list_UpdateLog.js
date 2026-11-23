const updateLogData = [
  {
    "title": "Chart data tips name the line they belong to",
    "date": "2026-11-23",
    "type": "feature",
    "content": "The data tips of the charts returned by plot_trajectory, plot_voltage, plot_iteration and the other chart plot methods, and of the side chart of plot_diagram and plot_spring_model, now start with the name of the element: the legend entry of the line or marker set, or its tag (for example the bus or generator) when it has none, and the tag of each bar. The x and y values below it, and z in a 3D panel, are labeled with the axis labels of the panel, for example \"t [s]\" and \"|V| [pu]\", instead of X and Y. The data tips stay right while the time shown changes or the chart is drawn again. Clicking a line still raises ElementClicked as before."
  },
  {
    "title": "Every GUILDA object opens its class reference page",
    "date": "2026-11-23",
    "type": "feature",
    "content": "The doc method of a network, bus, branch, component or controller, which opens the GUILDA reference page of its class in the browser, now works on the other GUILDA objects too: analysis results, solvers, solver methods, graphs, GUI windows, scenarios, events and parameter groups. For example, the result of a power flow calculation opens the page of its result class."
  },
  {
    "title": "Time responses beside the animated simulation plots",
    "date": "2026-11-22",
    "type": "feature",
    "content": "plot_diagram and plot_spring_model of a time simulation result now draw a side chart of a time response on the right of the animated figure, with a line that marks the time shown: the voltage magnitude of all buses for plot_diagram and the generator speed (omega) for plot_spring_model. The new option Trajectory chooses another quantity, as Quantity of plot_trajectory (for example \"Vangle\", \"P\" or a state name), and Trajectory=\"none\" draws the figure alone as before; drawing into a given axes also draws the figure alone. Write [G, G_chart] = res.plot_diagram() to get the side chart too. The playback bar of the figure moves the line of the side chart. The playback bar now appears only on figures whose drawing changes with time, such as network diagrams, spring models and eigenvalue plots of several sections; charts in which time only moves a cursor, such as plot_trajectory, the power flow convergence, the continuation power flow charts and the OPF iteration chart, have no bar of their own but still follow set_time, play, animate and the bar of a linked figure. In plot_iteration the bar is now below the network diagram. In the result window (launch_gui), the first figure with a playback bar starts playing by itself, also for the plot shown when the window opens."
  },
  {
    "title": "Bus heights of 3D network diagrams stand on a floor",
    "date": "2026-11-22",
    "type": "feature",
    "content": "In a 3D network diagram (plot_diagram with Dimension=\"3D\") with a BusHeightMode other than \"none\", the heights are now easy to read. Each bus stands on a thin post down to a light floor with a grid, the branches and links cast shadows on the floor, a translucent plane marks the reference value (|V| = 1 pu for \"V\", 0 for \"angle\", \"Vimag\", \"P\" and \"Q\"), and the z axis shows the values and the quantity, for example \"|V| [pu]\". The heights are scaled about the reference so that the values of all times fill a quarter of the drawing, and the floor and the scale stay the same while you move the time of a simulation result, so the posts can be compared across times. The diagram first looks at the heights from an oblique angle instead of from the top. The floor, posts, shadows and plane cannot be clicked and have no data tips. 2D diagrams and 3D diagrams with BusHeightMode \"none\" do not change."
  },
  {
    "title": "Network diagrams show the value behind each color",
    "date": "2026-11-22",
    "type": "feature",
    "content": "On a network diagram (plot_diagram, plot_lmp and the other maps colored by a value), the data tip of a bus, branch or component now has one line with the value that colors it, named as the colorbar, for example \"LMP [cost/pu] = 12.34\" or \"Loss [pu] = 0.04298\", after a small square of its color. With LabelMode \"value\", the labels of the buses and components also end with that value, and they follow the time shown and any color values set while the diagram plays. Elements without a value get no line."
  },
  {
    "title": "GraphChart draws 3D panels",
    "date": "2026-11-22",
    "type": "feature",
    "content": "A panel of the data of GraphChart can now be 3D: set l_3d = true in sct_panel (with s_zlabel and rv_zlim if needed) and give each line or marker series of the panel z values in rm_z, the size of rm_y. The panel draws one 3D line per column, for example P, Q and |V| of each bus, in a 3D view that you turn by dragging it or with the rotate button of the axes toolbar; clicking a line still raises ElementClicked. The automatic limits include z. A 3D time panel shows a marker at the point (x, y, z) of each line for the sample shown, so it follows set_time, the playback bar and a linked graph such as a 2D chart. iv_sample, the legend, colors, set_style and select work as in a 2D panel. Bars, reference lines and series without rm_z cannot go in a 3D panel, and rm_z in a 2D panel is an error (GUILDA:GraphChart:Panel3D), as is the line cursor (s_cursor \"line\") in a 3D time panel. Charts without 3D panels do not change."
  },
  {
    "title": "Select... for the targets of the linearization result forms",
    "date": "2026-11-22",
    "type": "feature",
    "content": "In the result window of a linearization (res.launch_gui()), the forms of get_contribution, get_reduced_matrix and plot_reduced_matrix now have a Select... button beside target. It opens a searchable table of the elements of the result (their tags and classes) and of their classes, and writes the rows chosen into the field, several at a time. The table is read only when the button is pressed, so the forms open as fast as before. When the result has no elements to list, a message says so and the field does not change."
  },
  {
    "title": "Time simulations use a tighter default relative tolerance",
    "date": "2026-11-21",
    "type": "fix",
    "content": "The default relative tolerance of time simulations is now 1e-6 instead of 1e-4; the absolute tolerance (1e-6) and the largest step (the solver default) do not change. With the looser tolerance, a long run in which the frequency does not return, such as a network without governors after a change of mechanical power, could stop partway with a message that the solver cannot meet the tolerance; it now runs to the end, and in our tests it takes about the same time. Results change slightly, by up to about 0.02 in the states of our test cases, about the error of the old default. At the first startup after the update, GUILDA shows the information message GUILDA:GUILDA:ConfigReset once and every time simulation setting (the tolerances, the solver, the progress display and the others) returns to its default; set again any of them you had changed."
  },
  {
    "title": "Quieter path setup and the verification folder on the path",
    "date": "2026-11-21",
    "type": "feature",
    "content": "A new Startup setting chooses whether adding and removing the GUILDA paths, at startup or by hand, prints its list of folders in the Command Window; it is on by default, as before, and a folder that fails to be added is reported either way. When the verification folder or the textbook folder is present at the GUILDA root, it is now added to the path with the other folders and removed with them; only the folder itself, not its subfolders. A copy of GUILDA without them works as before, without a message. The developer folder setting is removed: a saved value of it is dropped at the next startup."
  },
  {
    "title": "Built-in networks are built without their local controllers by default",
    "date": "2026-11-20",
    "type": "model",
    "content": "network.IEEE9bus, IEEE68bus, IEEJ_EAST10, IEEJ_EAST30, IEEJ_WEST10 and IEEJ_WEST30 now build with LocalController=false by default. LocalController=false now adds none of the AVRs, PSSs and governors of local_controller/, and every synchronous generator keeps its default Static AVR and governor (avr-static, gov-static), which hold Vfield and Pmech at their equilibrium. Before, the default was true, and false removed the Static AVR and governor too. The eigenvalues and time simulations of false are the same as before, as the Static controllers have no state. Write LocalController=true to keep the AVRs and PSSs (IEEE9bus, IEEE68bus) or the exciters and governors of the report (IEEJ); the Governor option of the IEEJ networks still works only with LocalController=true. The networks without bundled controllers (IEEE14bus, IEEE39Bus, TEST31bus, Txt3Bus, Tutorial3bus, Tutorial6bus, Tutorial10bus) do not change."
  },
  {
    "title": "VSG_classical swings on the virtual power of the classical machine",
    "date": "2026-11-20",
    "type": "model",
    "content": "The swing equation of the grid-forming inverter gfm-vsg-classical (component.GFMInverter.VSG_classical) now uses the virtual power P~ = Re(V conj(I0)) of the classical-machine current I0 = e^{j delta}(Iq - j Id), before its rotation by alpha into the bus, instead of the power Re(V conj(I)) of the rotated current I = e^{j alpha} I0 that enters the bus. P~ = cos(alpha) P - sin(alpha) Q. This is the phase-compensated VSG of Koizumi et al., with which a network whose lines all have the impedance angle alpha becomes lossless in the rotated frame. The class, the key and the parameters (M, D, Xd, Xq, alpha) are the same, and with alpha = 0 nothing changes. The power flow still fixes the bus P and Q; at the equilibrium Pref is now P~ and no longer the bus P. With alpha other than 0, the eigenvalues, the time simulations and get_hessian change."
  },
  {
    "title": "Graphs play from a playback bar below the axes",
    "date": "2026-11-20",
    "type": "feature",
    "content": "Every graph with two or more samples (res.plot_diagram(), plot_spring_model(), plot_trajectory() and the other charts that change with the time, GraphMatrix, the steps of a continuation power flow, ...) now has a bar below its axes, in a new figure and in a container given by Parent: a Play/Pause button, a time slider, the time or step shown and a speed dropdown (0.1x to 10x). Play runs without blocking MATLAB. The new property PlaySpeed is the same as the dropdown and is also the default Speed of animate, and the new methods G.play() and G.pause() do what the buttons do. Pause, closing the figure or deleting the graph stops the playback. Under matlab -batch and for hidden figures, Play does nothing. The time slider and the Play button were removed from the control panel of show_controls (and so from Display options of the result view of the GUILDA app). export_video does not record the bar."
  },
  {
    "title": "Result window: animated plots play from the playback bar",
    "date": "2026-11-20",
    "type": "feature",
    "content": "In the Analyze result window of the GUILDA app and of res.launch_gui(), a plot that animates (the network diagram or the spring model of a simulation) still starts playing as soon as it is drawn, now on the playback bar below the plot: its Play button shows Pause, Pause of the bar stops it, and the speed dropdown sets how fast it plays. It stops when the window closes or another plot replaces it. The iterations of an AC optimal power flow (res.plot_iteration()) also start playing: the chart of the iterations plays and the network diagram beside it follows. Other time charts, such as plot_trajectory(), do not start by themselves; press Play on their bar."
  },
  {
    "title": "Network diagrams color the components with the colormap",
    "date": "2026-11-20",
    "type": "fix",
    "content": "With ColorMode \"I\", \"P\" or \"Q\", net.plot_diagram(), res.plot_diagram() and the diagrams of the GUILDA app now color each component marker (generator, load, ...) by the value of its link on the same colormap and color limits, in 2D and 3D and at every time of an animation. A component without a value while the colormap is in use, with \"Loss\", a tripped unit or a NaN of ComponentColorData under \"user\", is black. Before, the markers kept their class colors (e.g. gold for generators), which could be read as values of the colormap. With ColorMode=\"none\" the class colors stay, and ComponentColor still overrides the color of a component."
  },
  {
    "title": "Network diagrams color the branch loss exactly",
    "date": "2026-11-20",
    "type": "fix",
    "content": "With ColorMode=\"Loss\", net.plot_diagram(), res.plot_diagram() and the diagrams of the GUILDA app now color each branch by its active-power loss P_from + P_to, the sum of the active powers that flow into the branch at its two ends. Before, the value was R|I_from|^2, which leaves out the line charging and the transformer tap: on IEEE68bus it was about 70 % too large on a line with a large charging (B042-B018) and 13 % too small on a transformer with tap 1.07 (B004-B019). The sum over the branches now equals the total loss of the power flow. A branch opened at one end shows the loss of the connected end."
  },
  {
    "title": "IEEJ standard networks use the ZIP load of the report",
    "date": "2026-11-19",
    "type": "model",
    "content": "The loads of network.IEEJ_EAST10, IEEJ_EAST30, IEEJ_WEST10 and IEEJ_WEST30 are now load-ZIP loads with the default parameters, the voltage characteristic of the report's load NLT=2: constant-current P and constant-impedance Q, both constant impedance below 0.7 pu. They were constant-impedance loads (load-impedance). The power flow is the same; the eigenvalues and the time simulations change, and the load tags end in LZIP1 instead of LRX1. The frequency characteristic of NLT=2 is still not represented. See each class help for the new stability results."
  },
  {
    "title": "Continuation power flow: network diagram, spring-mass model and more plots along the PV curve",
    "date": "2026-11-19",
    "type": "feature",
    "content": "A ResultCPF now keeps the operating point of every step of the path (tab_variable, rm_variable, the component currents cm_Icomponent and a snapshot sct_network), the voltage stability index rv_sigmaMin (smallest singular value of the power flow Jacobian, 0 at the nose), the weak buses at the nose tab_weakbus and the loading margin r_marginP. result.get_point(k) gives the point of step k, and net.get_sys({result, [1 result.r_noseStep]}) linearizes at the first point and at the nose, one section per step. New plots of the steps: result.plot_diagram (network diagram), result.plot_spring_model (spring-mass picture), result.plot_stability_index, result.plot_generator (P, Q or the Q margin of the generators, the Q-limit switches marked) and result.plot_branch (P, |S|, loading or loss of the branches, or the total loss). Every plot of the steps, plot_pvcurve included, takes the steps as samples, so G1.link(G2) keeps them together, with the new ResultLIN.plot_eigenvalue_path and plot_eigenvalue of several sections: G.set_time(k) moves a marker along the PV curves, and G.animate() plays one frame per step. animate and export_video now show every sample once when a graph names its samples and TimeStep is not given; graphs of seconds keep TimeStep 0.05. The new plots are also buttons of Analyze result in the GUILDA app."
  },
  {
    "title": "Network diagrams of a simulation show opened and faulted branches",
    "date": "2026-11-18",
    "type": "fix",
    "content": "The network diagram of a time simulation result, also in the result view of the GUILDA app, now computes the branch flows with the branch states of each moment of the run. A branch with all circuits opened carries no flow, a branch with one circuit opened carries the flow of the remaining circuits, and during a fault inside a branch both ends show the current that flows into the fault. Before, an opened branch kept showing the flow of the closed branch."
  },
  {
    "title": "GUILDA app: Analyze result stands out after a run, the diagrams stay at the equilibrium, and result plots play",
    "date": "2026-11-18",
    "type": "feature",
    "content": "In GUILDA.launch_gui, when an analysis or a simulation ends, Analyze result becomes the filled blue button (bold, white text), Run turns plain, and the status line ends with \"open Analyze result\"; once you open the result, or when a run fails, the buttons look as before. The network diagram on the left no longer switches to a drawing of the result: the Power flow, OPF and Time simulation tabs keep showing the network at the equilibrium with the conditions of the tab (bus types, the components with a cost, the targets of the scenario), and the time slider of the Time simulation tab is gone. Results are viewed in the Analyze result window. There, a plot that animates, such as res.plot_diagram or res.plot_spring_model of a simulation, starts playing as soon as it is drawn, as if Play had been pressed; the window stays usable, Pause in Display options stops it, and it also stops when the window closes or another plot replaces it. While an animation plays, the Play button of G.show_controls shows Pause, also when the animation was started by G.animate."
  },
  {
    "title": "Network diagrams leave out the widest branches when scaling widths",
    "date": "2026-11-18",
    "type": "fix",
    "content": "The branch widths of net.plot_diagram(), res.plot_diagram() and the OPF diagrams are now scaled from the smallest value to the 95th percentile of the quantity of BranchWidthMode, as the automatic color limits already were, instead of to the largest value. A few branches with a very large value, such as transformers with a large admittance under the default \"Ysvd\", no longer make all other branches thin: the top 5 % take the largest width of BranchWidthRange, and the others spread over the range. The marker sizes keep their scale from the smallest to the largest value, and BranchLineWidth still sets the width of a branch directly."
  },
  {
    "title": "Spring coils of a fixed size in the 2D spring-mass picture",
    "date": "2026-11-18",
    "type": "fix",
    "content": "The coils of the 2D spring-mass picture now have a fixed radius in pu (default 0.02 pu), so long springs such as the generator-to-bus springs no longer get oversized loops."
  },
  {
    "title": "GUI forms follow the component and the scenario you choose",
    "date": "2026-11-18",
    "type": "fix",
    "content": "In the GUI form that adds an input to a scenario, the list of input names now shows the inputs of the chosen component and changes when another component is chosen, keeping the names that the new component also has; the form that edits an added input does the same. The form that adds a scenario now starts with the name CASE and the time 0 to 10 s, and shows the time of the scenario to copy from when one is given. The forms for trips and branch openings take one time."
  },
  {
    "title": "Trips and branch openings take one time and last to the end",
    "date": "2026-11-18",
    "type": "feature",
    "content": "A trip of a component or controller and the opening of a branch in a scenario now take a single time instead of a start and an end: the unit or branch is disconnected at that time and stays disconnected until the end of the simulation, and reconnection is no longer offered. Change a two-number time to its first number. A trip or opening now gives one row in the event table, and a unit or branch can be tripped or opened by one event only. Faults, state offsets and added inputs keep their start and end. When adding an input to a scenario, code suggestions now offer the input names of the chosen component, and a new scenario gets the name CASE when no name is given."
  },
  {
    "title": "Network diagrams size the branch widths by admittance by default",
    "date": "2026-11-18",
    "type": "fix",
    "content": "The default BranchWidthMode of net.plot_diagram(), res.plot_diagram() and the OPF diagrams is now \"Ysvd\" (the largest singular value of the admittance matrix of the branch) instead of \"P\". Set BranchWidthMode=\"P\" to size the branches by the active power flow again; \"Q\", \"I\", \"G\", \"B\", \"Y\" and \"none\" are unchanged, and BranchWidthRange stays [1 4]."
  },
  {
    "title": "Faster GUILDA app, model GUI, option forms and result GUI",
    "date": "2026-11-18",
    "type": "fix",
    "content": "The GUIs now keep their parts and only update what changed. In GUILDA.launch_gui, switching tabs no longer redraws the network diagram: each tab keeps its own diagram, which is drawn again only after a run, so a switch takes a few hundredths of a second. In the model GUI (obj.launch_gui), moving to another bus, component, branch or the network takes about 0.1 to 0.2 s on IEEE 68-bus instead of up to a second or more, and the Parameter tab and the pages are drawn as web tables whose columns fit their header and contents, so the columns of the Scenario tables (Events, Offsets, Inputs, Settings) are no longer cut off. Text typed into a number cell is refused before anything runs. An option form opened a second time, and the dialog of a button in the result GUI, open in about 0.1 to 0.3 s, and a button shows at once that it was pressed. The code that the GUIs run and log is the same as before."
  },
  {
    "title": "delete removes a network diagram",
    "date": "2026-11-18",
    "type": "fix",
    "content": "delete(G) on a diagram of net.plot_diagram() or res.plot_diagram() now removes the diagram object; before, it only stopped the flow animation and G stayed valid, so a click on its old lines still called ElementClickedFcn."
  },
  {
    "title": "net.export saves the controllers, and PowerNetwork.import restores them",
    "date": "2026-11-18",
    "type": "feature",
    "content": "net.export now writes every local controller, the default Static AVR and governor included, to local_controller/<key>/parameter.csv (columns Component, FullTag and the parameters of the controller) and every global controller to global_controller/<key>/parameter.csv (one row per controlled generator). Values outside the parameter table, such as Q, R, Input and V0 of local-LQR and Q and R of pss-retrofit, go to option.json next to it. PowerNetwork.import attaches them again with their tags, so a network comes back with its controllers, and a scenario that trips a PSS or an AGC can be read again; the trajectories of net.simulate are the same. A local_controller folder is the complete set of local controllers: a generator without rows has none. An unknown controller key, a Component that is not in the folder, or two AVRs on one generator stop the import before the network changes. The warning GUILDA:PowerNetwork:ControllersNotSaved is gone. The bundled networks IEEE9bus, IEEE68bus and the IEEJ models keep their controllers in the same format; with Governor=false an IEEJ generator gets the Static governor tagged CG2 instead of CG1."
  },
  {
    "title": "Faster network diagrams in the GUILDA app",
    "date": "2026-11-18",
    "type": "fix",
    "content": "net.plot_diagram() reads only the parts of the network that the diagram shows, so it no longer copies the whole model first, and the label layout measures the label sizes once per drawing. Drawing a diagram again with net.plot_diagram(Graph=G) or res.plot_diagram(Graph=G) keeps the lines and labels when the network looks the same and only updates the colors, sizes, labels and flow arrows. In a window like the GUILDA app, a new IEEE 68-bus diagram is drawn about 20% faster and a redraw about twice as fast. Nothing changes in what is drawn."
  },
  {
    "title": "Network diagram labels stay next to their buses, and white flow arrows",
    "date": "2026-11-18",
    "type": "fix",
    "content": "In the 2D network diagram of net.plot_diagram() and res.plot_diagram(), the bus labels are now laid out again whenever the axes limits or the size of the diagram change, so they stay next to their buses and apart from each other. Before, they were placed once when the diagram was drawn, and in the GUILDA app they often ended up far from their buses or moved when you switched tabs, opened Display options, hid the log or resized the window. If you zoom or set the limits yourself, your limits are kept and only the labels move. The moving arrows of the flow animation are now white with a thin dark edge, so they stand out on the colored lines."
  },
  {
    "title": "Analysis tabs of the GUILDA app without a blank gap",
    "date": "2026-11-17",
    "type": "fix",
    "content": "In the analysis tabs and the time simulation tab of the GUILDA app, each option form now takes only the height of its fields, so the equilibrium section of the power flow tab and the time slider sit right under the form, and they move when you open or close a group. The fault position of a fault form shows bus for a bus fault, with a short hint, instead of NaN."
  },
  {
    "title": "network.Ishizaki6Bus is removed",
    "date": "2026-11-17",
    "type": "model",
    "content": "The bundled 6-bus network network.Ishizaki6Bus is removed, because the positions of its buses for the network diagram did not match its own lines. For a small network use network.Txt3Bus, network.Tutorial3bus or network.IEEE9bus; network.Tutorial10bus has a gen-classical generator like Ishizaki6Bus."
  },
  {
    "title": "Network diagrams read better on large networks",
    "date": "2026-11-17",
    "type": "feature",
    "content": "The colors of net.plot_diagram(), res.plot_diagram() and the OPF diagrams now use limits taken from the data of all times, leaving out the top outliers: 0 to the 95th percentile for |I| and the loss, and plus or minus the 95th percentile of |value| for P and Q (larger values take the end color), so most branches no longer saturate at the top of a fixed 0 to 2 scale. A numeric ColorLimits still fixes the limits, and ColorLimits=[NaN NaN] (the new default) makes them automatic again; in the control panel this is the Auto checkbox next to the color limits. The colorbar is labeled with the quantity, e.g. \"|I| [pu]\" or \"P [pu]\", unless ColorbarLabel is set. A field that is constant up to rounding, such as one price everywhere in res.plot_lmp(), now gets a few readable ticks instead of ten-digit ones. The diagram shows the bus tags only by default (the new LabelMode \"bus\"; LabelMode=\"tag\" shows the component tags too), and labels that would overlap are moved apart. The drawing fills the axes with a small margin in 2D and 3D, the bus and component marks are larger (MarkerSizeRange now [5 10] pt) with the buses drawn over the components next to them, and the title of a 3D diagram in a small figure no longer reaches the edge. Drawing a network without bus positions (such as IEEE 9-bus) again in the same session is faster."
  },
  {
    "title": "Cleaner spring-mass pictures in 3D and in small 2D plots",
    "date": "2026-11-17",
    "type": "fix",
    "content": "The 3D spring-mass picture no longer shows thin lines running out of the axes while a bus voltage is low or zero, for example during a ground fault, or when several 3D pictures share one figure; nothing is drawn outside the axes any more, and an arrow that would leave them is shortened along its direction. In the 2D spring-mass picture the angle and radius labels of the grid are thinned out when the plot is small, such as four plots side by side, so that they no longer overlap, and they come back when the plot grows; the radius labels now lie between two angle labels, the labels are drawn below the data and a label that would touch a node, a spring or an arrow is left out, so no label is half hidden, and labels you hide stay hidden."
  },
  {
    "title": "Clearer option forms in the GUIs, with pickers for tags and model keys",
    "date": "2026-11-17",
    "type": "feature",
    "content": "The option forms of the GUILDA app, the model GUI and the result GUI now show the main options first and the others in groups you open when you need them (Limits, OPF, Graph, Advanced, ...), with English labels and units. Every field shows its default (auto and none instead of NaN or Inf where that is what they mean, and a gray hint when the default is a setting); a changed field turns blue and ↺ puts the default back, and options that only apply to another choice (such as the OPF options of initialize) appear only when that choice is made. Fields that take tags of the network or a model key have a Select... button that opens a searchable table of the possible elements, and tags typed by hand are checked. The dialogs have Run and Cancel and fit their height to the form."
  },
  {
    "title": "The GUILDA app, the model GUI and the result GUI in English, with a clearer layout",
    "date": "2026-11-17",
    "type": "feature",
    "content": "All the text of GUILDA.launch_gui, obj.launch_gui and res.launch_gui is now in English: the tabs are Model, Power flow, OPF, CPF, Time simulation and Linearization. In the app the network diagram fills its panel and gets most of the height: the run log is smaller, and Hide log hides it. A second line over the diagram says what its colors mean, and the colorbar has a label. After a power flow the branches are colored by their active power with arrows, while before it only the bus types are colored, so the result stands out. Display options shows the control panel of a diagram or a plot that has one. Run, Analyze result and the status of the last run sit right under the title of each analysis tab, and the time slider of the simulation tab appears only with a result. In the model GUI the children are listed one kind at a time in a searchable table (Bus (14), Branch (20), ...); click a row to show that model, or right-click it to open it in a new window or remove it. Parameter containers of one row are shown as a Name/Value list with the full names. The result GUI labels its buttons in words (Voltage, Summary, Export to file; the method name is in the tooltip) and opens with the summary and the first plot."
  },
  {
    "title": "Saved figures of charts and spring models no longer carry a copy of the graph",
    "date": "2026-11-17",
    "type": "fix",
    "content": "Saving a figure with a chart of res.plot_trajectory(), the power flow, CPF, linearization and OPF charts, a spring model of plot_spring_model(), or any graph with a panel of G.show_controls() (savefig, Live Editor outputs) no longer stores a copy of the graph object in the file, so large figures no longer warn about a recursion limit and openfig no longer brings back a stray graph. A graph now lives as long as its axes, also when you do not take the output (res.plot_trajectory(); then clicks and the panel still work), and closing the figure frees it unless you keep G."
  },
  {
    "title": "Network diagrams in one place: 2D, ranges, moving flow and a control panel",
    "date": "2026-11-17",
    "type": "feature",
    "content": "The network diagram of net.plot_diagram(), res.plot_diagram() and the OPF diagrams is now a light 2D single-line diagram (Dimension=\"3D\" keeps the solids, and BusHeightMode works in both), with branch widths and marker sizes in points mapped onto BranchWidthRange and MarkerSizeRange over all times of a result, dots that move along the lines in the direction of the power flow (FlowMode, FlowAnimation, FlowSpeed), and a panel of controls that G.show_controls() adds to any graph. BranchWidthScale, BranchWidthOffset and the scalar MarkerSize are removed: use the ranges, or MarkerSizeRange=[s s] for one size. The new For Developer page Features: Graphs describes how the graphs are built and how to extend them."
  },
  {
    "title": "Panels of controls for network diagrams and power flow maps",
    "date": "2026-11-17",
    "type": "feature",
    "content": "G.show_controls() now also works for the network diagram of net.plot_diagram(), res.plot_diagram() and the OPF diagrams, and for the map of res.plot_network(). For a network diagram the panel has dropdowns for the drawing (2D or 3D), the bus heights, the color, the branch widths, the marker sizes, the flow dots and the labels; two spinners each for the color limits and the ranges of the branch widths and marker sizes; spinners for the link width and the label font size; a button that starts and stops the moving flow dots and a slider for their speed (both disabled in 3D, which has no dots); and, for a simulation result, the time slider with Play/Pause. Switching between 2D and 3D in the panel keeps the panel and its settings. For a power flow map the panel has the range of the branch widths only: the bus colors and the arrows are chosen when the map is drawn (Color= and Arrow= of res.plot_network). As for the other graphs, the controls only set the properties of G, and setting a property in code updates the panel."
  },
  {
    "title": "Power flow shown as moving dots on network diagrams",
    "date": "2026-11-17",
    "type": "feature",
    "content": "In the 2D network diagram of net.plot_diagram(), res.plot_diagram() and the OPF diagrams, small triangles now move along every branch and component link in the direction of the power flow, at a speed proportional to the flow, so the direction and the size of each flow can be read at a glance. G.FlowMode chooses the flow: \"P\" (active power, default), \"Q\" (reactive power), \"I\" (current, in the direction of P) or \"none\" (no dots). The dots are 0.25 times the median branch length apart on every line; G.FlowSpeed (default 1) sets how far the dots of the largest flow move per second, in that same length, and one scale covers all times of a simulation. For a simulation result the dots follow the time shown by G.set_time, a linked graph or G.animate, and G.export_video moves them by the time between its frames. The dots move by a timer while the figure is visible; G.FlowAnimation = false stops them where they are, and a still image still shows the direction. A diagram made in a hidden figure (and under matlab -batch) does not start the timer: after showing the figure, set G.FlowAnimation = true. Closing the figure or deleting G stops the timer. In 3D (Dimension=\"3D\") there are no dots; the arrow cones point in the direction of the same flow (BranchDirection and LinkDirection are now the signs of the flow of FlowMode)."
  },
  {
    "title": "AVR limiters you can switch off, and limited AVRs on the IEEE 68-bus network",
    "date": "2026-11-17",
    "type": "model",
    "content": "controller.avr.AVR_ST1 and controller.avr.AVR_DC1 have a new dynamics parameter Limiter (true by default). Set it to false, e.g. avr.tab_parameter.dynamics.Limiter = false, to ignore all limits of that AVR, including the range check at the equilibrium; the error for an amplifier output outside its limits now says so. The limit of AVR_ST1 is now non-windup: Vap stops at Vap_max or Vap_min instead of only the output being clipped. The 16 AVRs of network.IEEE68bus now have Vap_max = 5 and Vap_min = -5 pu, the field voltage limit of the static exciters in the 68-bus benchmark data, so responses that leave the equilibrium far behind, such as faults, change; the equilibrium and the linearization do not. Set Limiter to false on every AVR to get the earlier results. network.IEEE9bus and the IEEJ networks list Limiter = 1 in their AVR data and keep their results."
  },
  {
    "title": "Network diagrams are drawn in 2D by default, with sizes and widths in fixed ranges",
    "date": "2026-11-17",
    "type": "feature",
    "content": "net.plot_diagram(), res.plot_diagram() and the OPF diagrams now draw a light single-line diagram in 2D: bus bars as line segments, buses and components as markers, branches and links as lines, and a transformer as two circles near its from end. The solids with lighting stay available with Dimension=\"3D\", and G.Dimension switches the drawing at any time. Both use the bus heights of BusHeightMode, and the view you rotate to is kept when the diagram is drawn again. Sizes and widths are in points: BranchWidthMode (now \"P\" by default, also \"Q\" and \"I\") is mapped from its smallest to its largest value onto BranchWidthRange (default [1 4]), and the new MarkerSizeMode (\"none\", \"P\", \"Q\", \"S\") onto MarkerSizeRange (default [4 8]); one scale covers all times of a simulation. LinkWidth sets the width of the component links. BranchWidthScale, BranchWidthOffset and MarkerSize are removed: use the ranges, or MarkerSizeRange=[s s] for one size. BusMarkerSize, ComponentMarkerSize and BranchLineWidth are in points and override the ranges. res.plot_network() gets BranchWidthRange too, and its default bus size is 6. Also fixed: a diagram drawn before a power flow no longer shows an empty colorbar; saving a diagram figure (savefig, Live Editor outputs) no longer warns about a recursion limit; drawing is faster (IEEE9 in about 0.3 s and IEEE68 in about 0.6 s in 2D); and the title and the colorbar label of res.plot_lmp() are no longer cut off (the colorbar is now right of the diagram)."
  },
  {
    "title": "Choose tags and model keys from a searchable table",
    "date": "2026-11-17",
    "type": "feature",
    "content": "DrawerTagPicker.pick(fig, tab) shows a table in a window with a search box and returns the tags of the rows you choose (or nothing on cancel); Multiple=true allows several rows and Selected preselects some. DrawerTagPicker.element_table(net, kind) gives the table of the buses, branches, components, local controllers, global controllers or scenarios of a network, with the columns that tell them apart, such as the bus of a component, its position on that bus and its class. DrawerTagPicker.key_table(category) lists the model keys of a category with their class and description; pick it with Column=\"Key\"."
  },
  {
    "title": "Run time simulations in the GUILDA app",
    "date": "2026-11-17",
    "type": "feature",
    "content": "The tab 時間シミュレーション of GUILDA.launch_gui lists the scenarios of the network. 追加 and 削除 add and remove a scenario, and the scenario selected opens below in its model GUI, where you add and remove its events (faults, trips, branch openings, offsets and inputs). The network diagram marks the buses, branches and components the scenario acts on. The form of net.simulate runs the scenario selected as [res_ode, flag_ode] = net.simulate(...); the diagram then shows the result, with a time slider, and 結果を解析 opens the result GUI in a new window on the same log. Every action is a line of the run log and of the exported script."
  },
  {
    "title": "Scenario events you can edit, and better code suggestions",
    "date": "2026-11-17",
    "type": "feature",
    "content": "Each disturbance of a scenario is now an event object: EventFault, EventTrip, EventOpenBranch, EventOffset or EventInput. sc.add_fault, sc.add_trip, sc.add_open_branch, sc.add_offset and sc.add_input add one and return it, so you can change it later with ev.edit(Name=Value), using the options of the add_* method; for example ev = sc.add_fault(\"B008\", [1, 1.05]); ev.edit(Time=[1, 1.1]). After an edit the scenario checks all its events again, and an edit that fails a check is undone. sc.remove_event(tag) removes events (in the GUI: Remove event on a row of the event tables). The event classes can also be created without a network and copied into a new scenario: net.add_scenario(\"case1\", Event={EventFault(\"B008\", [0.1, 0.17]), EventOpenBranch(\"EL003\", [0.17, 20])}). The tables tab_event, tab_offset and tab_input keep their columns and are built from the events; the scenario files are unchanged. In a ResultODE, the inputs (u and uc) of a tripped component, local controller or global controller are now NaN while it is tripped, like its states and outputs and like Format=\"struct\"; before, they were 0. Tab completion now works for the methods of Scenario, of the event classes (their constructors and edit), of the analysis results (ResultPF, ResultOPF, ResultCPF, ResultODE, ResultLIN) and for get_sys. For example, sc.add_fault( and net.a_Scenario{1}.add_fault( list the bus and branch tags of the network, and res.plot_voltage(Quantity= lists magnitude, angle and both. res.plot_trajectory(Quantity= of a simulation result lists Vabs, Vangle, P, Q and the state and input names of the components (such as omega), and Bus= lists all and the bus tags. Other values can still be typed. For developers: GUILDA.update_keymap(Signature=true) now also writes _GUILDAsystem/_auxiliary/resources/functionSignatures.json with the entries of the classes in _auxiliary, because MATLAB applies a resources/functionSignatures.json only to the folder that holds it; _GUILDAsystem/resources/functionSignatures.json keeps every entry for the GUI. The type of an argument declared with size (1,1) now has the attribute scalar, which the GUI uses to offer a single choice."
  },
  {
    "title": "A panel of controls for spring-mass pictures and charts",
    "date": "2026-11-17",
    "type": "feature",
    "content": "G.show_controls() puts a panel of controls next to a graph returned by plot_spring_model or by a plot_* that draws a chart (such as res.plot_trajectory). It shows checkboxes for the labels, the values and the legend, a slider for RotationScale and spinners for ArrowScaleP and ArrowScaleQ of a spring-mass picture (and the surface opacity SurfaceAlpha in 3D), and, for a graph with two or more samples, a time slider with a Play/Pause button and the time shown (a chart only when it has a time panel). The controls only set the properties of G, so changing a control is the same as setting the property in code, and setting a property in code (or moving the time with G.set_time, a linked graph or G.animate) updates the panel. A value the property refuses puts the control back. G.show_controls(Parent=h) fills a figure, uifigure, uipanel, uitab or uigridlayout instead, for example a cell of your own app, and ChangedFcn=@(G, name, value) ... is called after each change made in the panel. G.hide_controls() removes the panel and gives the axes back their place; deleting the axes deletes the panel. No plot_* shows the panel by itself."
  },
  {
    "title": "Progress display for the power flow, OPF and continuation power flow",
    "date": "2026-11-16",
    "type": "feature",
    "content": "net.calculate_powerflow, net.calculate_fixed_input_powerflow, net.calculate_optimal_powerflow and net.calculate_continuation_powerflow take the option Progress, like net.simulate: \"dialog\" (default) shows a dialog with the iteration (the power flow), the solver and the fmincon iterations with the cost and the constraint violation (the OPF; the outer iterations of the stability-constrained OPF), or the step and lambda (the continuation power flow); \"disp\" prints one line per step in the Command Window; \"none\" shows nothing; true and false mean \"dialog\" and \"none\". The dialog opens only when the calculation lasts 0.5 s or longer, so short calculations show nothing, and it closes at the end, also on an error. Inside the GUILDA app (GUILDA.launch_gui) it is a dialog of the app window. The dialog of net.simulate now also covers the preparation of the run before the integration. Under matlab -batch no dialog is shown. Set the default with GUILDA.setting(\"PowerFlowCalculation\", Progress=\"none\") and the same key in OptimalPowerFlow and ContinuationPowerFlow. net.initialize shows no progress unless the call gives Progress. Verbose still prints the details of each iteration and stays false by default."
  },
  {
    "title": "Network diagrams read the new layout columns and place new buses near their neighbours",
    "date": "2026-11-16",
    "type": "feature",
    "content": "net.plot_diagram() and res.plot_diagram() now draw a bar bus centered at X, Y, connect branches and components on the center line of the bar at FromOffset, ToOffset and Offset (a NaN offset takes the nearest bend point projected onto the bar, or the center), place a component at DX, DY from the center of its bus, and draw the transformer symbol of Style \"transformer\" at the from end. A bus without a position no longer moves every other bus into the force layout: the buses with a position stay exactly where they are, and new buses are placed near the buses they connect to (a bus without a branch goes to the right of the drawing), the same way every time; only a network where no bus has a position uses the force layout. res.plot_network() places buses the same way. A component without a position is put around its bus at a distance that scales with the spacing of the buses. The positions placed automatically stay in the graph; G.get_layout() returns the drawn positions (G = net.plot_diagram() or res.plot_network()) and net.set_layout(G.get_layout()) saves them, also after G.set_position. Moving a bus with G.set_position moves its components and their connection lines with it."
  },
  {
    "title": "Spring-mass pictures of networks with bus bars",
    "date": "2026-11-16",
    "type": "fix",
    "content": "net.plot_spring_model() and res.plot_spring_model() (2D and 3D) no longer stop with an error on networks whose buses are drawn as bars, such as network.IEEE14bus. The Shape of the graph parameters of a bus or component gives the marker of its node: \"circle\" is drawn as \"o\", \"square\" as \"s\", \"^\", \"v\", \"<\", \">\" and \"none\" as they are, and a bar (\"hbar\" or \"vbar\") as the default \"o\". In 3D, \"v\" is a cone and every other marker a sphere, as before. G.get_layout() of a spring-mass picture stops with an error: its node positions are the voltage phasors, not a layout to save with net.set_layout."
  },
  {
    "title": "Analysis tabs in the GUILDA app",
    "date": "2026-11-16",
    "type": "feature",
    "content": "The tabs 潮流計算, 最適潮流計算, 連続潮流計算 and 近似線形解析 of GUILDA.launch_gui now run their analyses. Each tab shows the options of its method as a form (the current GUILDA.setting values first), a button 実行, the flag and the elapsed time of the last run, and a button 結果を解析 that opens the result GUI in a new window on the same log. The run is written as one line, such as [res_pf, flag_pf] = net.calculate_powerflow(Solver=\"fsolve\");, with only the options you changed, and the latest result of each tab is kept as res_pf, res_opf, res_cpf or res_lin. The diagram follows the tab: the bus types before a power flow and its result after it, the components with a cost before an OPF and the LMP after it, and the load buses used by a continuation power flow. 潮流計算 also has the form of net.initialize, whose options start empty and are left out unless you set them; 連続潮流計算 and 近似線形解析 show a banner while the network needs net.initialize(). In 連続潮流計算, LoadBus starts with the buses that have a load when net.solver_CPF.LoadBus is empty."
  },
  {
    "title": "Start the GUILDA app with GUILDA.launch_gui",
    "date": "2026-11-16",
    "type": "feature",
    "content": "GUILDA.launch_gui() opens the GUILDA app. Without a network, a start screen makes an empty network, loads a sample network of +network (such as network.IEEE14bus), a model folder written by net.export, or a MATPOWER case; GUILDA.launch_gui(net) starts with your network. The left half shows the network diagram, drawn again after every action, over the run log; the right half shows the active tab of the tab bar across the top. In the tab 系統モデルの作成 a click on a bus, branch or component of the diagram opens it in the model GUI, and the model shown is selected in the diagram, also when you move with the breadcrumb or the child cards. Every action, including the choice of the start screen, runs as a line of MATLAB code in one log, and the button スクリプトを出力 writes a script that repeats the session. The tabs for the analyses show 準備中 for now."
  },
  {
    "title": "Clearer layout columns for network diagrams, and net.get_layout / net.set_layout",
    "date": "2026-11-16",
    "type": "feature",
    "content": "The graph parameters that place buses, branches and components in network diagrams have new columns, each with one meaning. Buses: X and Y are the center of the bus (also of a bar), Shape is \"square\" (default), \"circle\", \"hbar\", \"vbar\", \"^\", \"v\", \"<\", \">\" or \"none\", and Length is the length of a bar. Branches: Path holds the bend points as \"x y; x y\" (add_branch also takes an n x 2 matrix), FromOffset and ToOffset give where the branch meets the bar of its end buses, and Style is \"line\" or \"transformer\" (the symbol at the from end). Components: DX and DY are the position from the center of the bus, so a component follows its bus, Path holds the bend points of the connection line from the bus center, Offset gives where it meets the bar, and Shape is the marker. MarkerSize and Color are unchanged. The old names Xaxis, Yaxis, Marker, MidXaxis and MidYaxis are removed. Every value is checked when it is given, also when a table is written directly or from the GUI: a broken Path, an unknown Shape or Style, or a bar without Length stops with an error and nothing changes. net.get_layout() returns the layout of all elements as tables with a Tag column, and net.set_layout(L, IgnoreUnknown=false) writes all or part of it back after checking every row. PowerNetwork.import stops at the old columns; convert your own model folders once with tools.layout_convert_columns(folder). The bundled networks are converted. res.plot_network() now draws a bar bus at its center. Scripts that use the old names need updating."
  },
  {
    "title": "A GUI for every analysis result",
    "date": "2026-11-16",
    "type": "feature",
    "content": "res.launch_gui() opens a window for any analysis result (power flow, OPF, CPF, time simulation, linearization): a header with the class, the success state, a summary line and a Docs button; the plot_, disp_, get_ and export methods of the result as buttons grouped as Plot, Display, Get and Export; and tabs for the plot, the text and the log. A button with options asks for them in a dialog. Every action runs as a line of MATLAB code (for example G = res.plot_voltage(Quantity=\"angle\", Parent=h_parent);), printed in the Command Window as >> code, and h.history.get_script() returns a script that repeats them, drawing the plots in new figures. res.launch_gui(container, History=hist, Variable=\"res_pf\") embeds the GUI in a uifigure, uipanel, uitab or uigridlayout and records the actions in the log of an app."
  },
  {
    "title": "No thin lines in captured network diagrams",
    "date": "2026-11-16",
    "type": "fix",
    "content": "Images of a network diagram (net.plot_diagram(), res.plot_diagram(), plot_lmp and plot_iteration of an OPF result) captured with getframe, exportapp or exportgraphics at 150 dpi no longer show thin horizontal and vertical lines running from the buses to the edges of the image. The lines came from a MATLAB rendering problem with the edges of the bus bars and boxes, which are now drawn without edges; the diagram looks the same otherwise. They were not grid lines, so GridSpacing has no effect on them."
  },
  {
    "title": "Add and remove models from the model GUI",
    "date": "2026-11-16",
    "type": "feature",
    "content": "The model GUI (obj.launch_gui()) can now build the model. Buttons above the child cards add a bus, branch, global controller or scenario to a network, a component to a bus, a local controller to a component (or a PSS under an AVR), and a fault, trip, branch opening, offset, input or disturbance to a scenario; each opens a form of the options of the method, whose tag inputs list the tags of the model. Remove in the context menu of a card removes that model, and Remove disturbance on a row of the Events, Offsets or Inputs table of a scenario removes that disturbance, after a confirmation. Every action, and every parameter edit, runs as one line of MATLAB code, such as net.a_Bus{3}.add_component(\"gen-park\"); or net.a_Bus{1}.tab_parameter.powerflow.V = 1.02;, which is printed in the Command Window and logged: h.history.get_script() returns the code of the actions as a script. obj.launch_gui(History=hist) logs the actions in a HistoryGUILDA of your own."
  },
  {
    "title": "Chart panels in a grid and a callback when the time changes",
    "date": "2026-11-16",
    "type": "feature",
    "content": "A chart (GraphChart) can lay its panels out in a grid: the data field rv_grid = [n_row n_col] gives the rows and columns of the tiles, the panels fill them row by row (panel 2 of a 2 x 2 grid is at the top right), and without it the panels stay in one column. set_data keeps the grid, so it needs the same rv_grid. Every graph (GraphBase) now raises the event TimeChanged and calls G.TimeChangedFcn(G, data) after set_time has drawn it, also when it moves with a linked graph and at every frame of animate and export_video; data (GraphTimeEventData) holds Time and Index of the sample shown, so a callback can, for example, write a title or set styles for each time. A set_time called from such a callback leaves the graphs of the running set_time as they are, so callbacks that move linked graphs do not loop."
  },
  {
    "title": "Power flow charts return a chart object",
    "date": "2026-11-16",
    "type": "feature",
    "content": "res.plot_voltage(), res.plot_branch() and res.plot_convergence() of a power flow now return a chart G (GraphChart, as res.plot_trajectory() of a time simulation) instead of the tiled layout or the axes; the axes are G.ax. Each bar is an element tagged with its bus or branch tag (the |V| and angle bars of a bus share the tag), the Vmin and Vmax lines of plot_voltage are tagged \"Vmin\" and \"Vmax\", the residual line of plot_convergence \"Residual\" and its |V| lines with the bus tags, so G.set_style, the Series* vector properties, select and ElementClicked work on them. The options and the drawing are unchanged. A graph drawn into a uigridlayout now goes into a borderless uipanel in the next free cell, without the MATLAB warning that a grid layout does not support a tiled layout; to choose the cell, set Layout of G.ax(1).Parent.Parent."
  },
  {
    "title": "PV curve and eigenvalue map return chart objects",
    "date": "2026-11-16",
    "type": "feature",
    "content": "res.plot_pvcurve() of a continuation power flow and res.plot_eigenvalue() of a linearization now return a chart G (GraphChart, like res.plot_trajectory()) instead of the axes; the axes are G.ax. In the PV curves each line is an element tagged with its bus tag; the nose line is fixed drawing. The eigenvalue map has two marker sets tagged \"stable\" and \"unstable\" (a set without points when there is none), so for example G.set_style(\"unstable\", MarkerSize=12) enlarges the unstable eigenvalues and G.reset_style() returns to blue and red. The options and the content of the plots are unchanged; scripts that use the returned axes need G.ax."
  },
  {
    "title": "plot_trajectory returns a chart object",
    "date": "2026-11-16",
    "type": "feature",
    "content": "res.plot_trajectory() of a time simulation now returns a chart G (GraphChart, a GraphBase like the spring model and the network diagram) instead of the axes; the axes are G.ax. Each line is an element tagged with its bus tag, or with the full tag of its component for a component quantity, so G.set_style(tags, Color=, Label=, LineWidth=, LineStyle=, Marker=, MarkerSize=, Visible=), the vector properties SeriesColor, SeriesLabel, SeriesLineWidth, SeriesMarker, SeriesMarkerSize, SeriesLineStyle and SeriesVisible (NaN colors follow the color order), select, reset_style and ElementClicked work on the lines. G.set_time(t) draws a time cursor, and G.link(S) with res.plot_spring_model() or res.plot_diagram() moves the cursor with their animation. The options and the content of the plot are unchanged; scripts that use the returned axes need G.ax."
  },
  {
    "title": "Power flow network map as a graph object",
    "date": "2026-11-16",
    "type": "feature",
    "content": "res.plot_network() of a power flow now returns a GraphNetMap object G instead of the graph plot; the drawing is the same, and the graph plot is G.sct_plt.Graph. Like the other graphs (GraphBase), G.tab_element lists the buses and branches, G.set_style(tags, Color=, Label=, Marker=, MarkerSize=, LineWidth=, LineStyle=) changes them, and so do the vector properties BusColor, BusLabel, BusMarkerSize, BusMarker, BranchColor, BranchLineWidth and BranchLineStyle (NaN rows of BusColor keep the color of the voltage, and of BranchLineWidth the width of the flow); G.reset_style returns them to the defaults. G.set_position(tags, xy) moves buses in the drawing only, G.ColorbarLabel sets the label of the colorbar, a click on a bus or branch raises ElementClicked, and G.select(tags) highlights them. Parent may be a container (figure, uifigure, uipanel, uitab, uigridlayout) or an axes or uiaxes. Scripts that used the returned graph plot h need h = G.sct_plt.Graph."
  },
  {
    "title": "Title and colorbar label of the network diagram",
    "date": "2026-11-16",
    "type": "feature",
    "content": "The network diagram (GraphNetDiagram) has two new properties: TitleFormat sets the title written at each sample, as sprintf(TitleFormat, t) with the time t of the sample (default \"t = %.2f s\"; \"\" keeps the title you set with title), and ColorbarLabel sets the label of the colorbar. Both, and a title you set, now stay when the diagram is drawn again. The title of the diagram also appears in the figure and in images written with exportgraphics, where it used to fall outside, and a selected branch or link with mid points is now marked along its bent path."
  },
  {
    "title": "Common methods for every graph: styles, selection, clicks, links and the topology diagram",
    "date": "2026-11-14",
    "type": "feature",
    "content": "The graphs returned by plot_spring_model and plot_diagram now share one base class, GraphBase. G.set_style(tags, Color=, Label=, Marker=, MarkerSize=, LineWidth=, Visible=) changes the elements with those tags, and G.tab_element lists the elements with their tag and kind; the same appearance is in vector properties, for example NodeColor, NodeSize and EdgeLineWidth of the spring model, or BusColor and BranchColor of the network diagram (RGB colors that stay over ColorMode) and its BusMarkerSize, ComponentMarkerSize and BranchLineWidth (sizes of each element, where NaN keeps MarkerSize and the width of BranchWidthMode); MarkerSize and LineWidth of set_style take one value or one per tag. G.set_data(data) replaces the data and keeps the appearance of the elements that are still there, G.link(G2) makes another graph follow set_time, and G.set_position(tags, xy) moves buses and components of the network diagram in the drawing only. G.reset_style(tags) returns elements to the defaults of the data. A click on an element raises the event ElementClicked and calls G.ElementClickedFcn(G, data), where data (GraphEventData) holds Tag, Kind and Index, and G.select(tags) / G.clear_selection() highlight elements in SelectionColor without changing their style. The Parent of every graph is a container (figure, uifigure, uipanel, uitab or uigridlayout, where the graph makes a tiled layout) or an axes or uiaxes. net.plot_diagram has the option State: \"auto\" (the default) draws only the topology, with an INFO message, when the network is not initialized or not up to date, \"topology\" always does, and \"equilibrium\" keeps the former error; net.plot_diagram(Graph=G) draws the current network again into an existing diagram and keeps its styles, positions and selection. The network diagram can now be animated and written to a video with animate and export_video. DrawerNetDiagram is renamed GraphNetDiagram, its error identifiers become GUILDA:GraphNetDiagram:*, and the appearance fields of the spring model data are read from NodeColor, NodeSize and NodeMarker instead of sct_data, so scripts that use the old names need updating; scripts that expect net.plot_diagram to stop on a network that is not up to date need State=\"equilibrium\"."
  },
  {
    "title": "Model GUI opened with launch_gui",
    "date": "2026-11-14",
    "type": "feature",
    "content": "The GUI of a network, bus, branch, component, controller or scenario now opens with obj.launch_gui(), or obj.launch_gui(container) to fill a panel of your own app; the method gui is renamed, and the GUI itself is unchanged. Scripts that call gui need updating."
  },
  {
    "title": "Branch faults, circuit opening and controller trips in scenarios",
    "date": "2026-11-14",
    "type": "feature",
    "content": "A scenario can ground a branch along its length and open one of its circuits: sc.add_fault(\"EL003\", [0.10, 0.17], Status=\"3LG\", Point=0.3) grounds one circuit at 30 % from the from end (\"6LG\": all circuits), and sc.add_open_branch(\"EL003\", [0.17, 20], Status=\"3open\") opens one circuit (\"6open\", the default, opens all of them). Branches have a number of circuits: add_branch(..., Circuit=n) (default 2) and the column circuit of branch/parameter.csv; R, X and C stay the values of all circuits together, so the power flow does not change. br.get_admittance_matrix(Status=, Point=) gives the matrix of a branch in each state, and net.get_admittance_matrix(BranchStatus=tab) that of the network for a table of branch states. sc.add_trip now also trips local controllers. While a component or controller is tripped, an input that it drives or that observes it takes its equilibrium value, as if it were not connected; a global controller that observed a tripped component read 0 before. A tripped AVR thus keeps the field voltage at its equilibrium; model a loss of excitation with sc.add_input(gen, \"Vfield\", -Vfield0, [t1, t2]). The disturbances of a scenario are now in three tables: tab_event (faults and parallel events, two rows per target with the tags Fault001, Parallel001, ...), tab_offset and tab_input; tab_disturbance is removed. add_fault, add_trip and add_open_branch no longer take Tag, add_disturbance no longer takes FaultBus, TripUnit and OpenBranch, and two faults or two parallel events of one target may no longer overlap. Scenario files are written in version 2; files of version 1 are no longer read, so build those scenarios again and write them with net.export. The columns of output.phases are the new tags. Scripts that use the removed options or tab_disturbance need updating."
  },
  {
    "title": "The network diagram no longer changes the network",
    "date": "2026-11-13",
    "type": "feature",
    "content": "net.plot_diagram(Parent=ax) draws the equilibrium from a snapshot of the network and no longer writes the positions of its automatic layout into the graph parameters of the buses; it needs an initialized network (\"Run net.initialize() first\" otherwise). Other Name-Value options set the properties of the diagram, for example net.plot_diagram(ColorMode=\"P\", BusHeightMode=\"V\"). result.plot_diagram() of a power flow draws the solution, and that of a time simulation holds every output time: G.set_time(t) shows one of them, with the current of each component from the simulation. The properties of DrawerNetDiagram are renamed: ColorLimits, Colormap, BranchWidthMode (\"Ysvd\"), BranchWidthScale, BranchWidthOffset, BusHeightMode (\"V\", \"angle\", \"Vimag\"), BusColorData, ComponentColorData, BranchColorData, LinkColorData, BranchDirection, LinkDirection, BusLabel, ComponentLabel, LabelMode (\"tag\", \"value\"), LabelFontSize, LabelFontWeight and GridSpacing; the ColorMode values are \"I\", \"P\", \"Q\", \"Loss\", \"none\" and \"user\". G.set_time(t) shows a sample, and set_network and set_powerflow are no longer public. The old names and the positional axes argument are removed, so scripts that use them need updating."
  },
  {
    "title": "Current of each component in time simulation results",
    "date": "2026-11-13",
    "type": "feature",
    "content": "The result of net.simulate has a new property rm_Icomponent: the current each component injects into its bus (Ireal, Iimag of each component, bus by bus, positive into the bus), evaluated with the current function of the component at every output time and NaN while the component is tripped. The currents of the components of a bus add up to the bus current rm_I within the tolerance of the solver, except at a faulted bus during the fault. odeResults.Bus(i).Component(j).I gives the same values as a table [Ireal, Iimag], and result.export writes them in the columns <component>_Ireal and <component>_Iimag."
  },
  {
    "title": "Spring-mass pictures of the network and of the results",
    "date": "2026-11-13",
    "type": "feature",
    "content": "net.plot_spring_model(Dimension=2) draws the equilibrium of the network as a spring-mass picture: the nodes are the voltage phasors of the buses and the internal voltages of the generators, the springs are the branches and the machine reactances, and arrow pairs show the active power P and the reactive-current magnitude Iq. Dimension=3 puts the nodes on the surface z = log|V|. It needs an initialized network (\"Run net.initialize() first\" otherwise). result.plot_spring_model(...) of a time simulation holds every output time, so G.animate() plays it and G.export_video(\"swing.mp4\") writes a video; that of a power flow shows the buses only. The old argument mode of net.plot_spring_model is removed. The graph parameters of buses and components have two new columns, MarkerSize and Color, that set the size and color of the nodes; CSV files write them, and older CSV files without them still load."
  },
  {
    "title": "The slack bus is no longer selected automatically",
    "date": "2026-11-13",
    "type": "feature",
    "content": "GUILDA no longer chooses a slack bus. Set it yourself before the power flow, e.g. net.a_Bus{1}.l_isSlack = true (usually a bus with a generator whose powerflow Q is NaN). Without one, net.calculate_powerflow, net.calculate_fixed_input_powerflow, net.initialize and the new net.get_pf_condition stop with GUILDA:PowerNetwork:NoSlackBus, whose message shows how to set it. net.get_pf_condition() returns the data of the power flow, as net.get_opf_condition() does for the OPF: Bus (Type, Varg, V, P, Q of each bus) and Y (the admittance matrix as a table); it prints the Bus table unless Display=false. The packaged networks and the networks read with PowerNetwork.import or import_matpower set their slack bus from their data. The OPF needs no slack bus: ReferenceBus=\"auto\" is the slack bus if one is set, else the first bus. Scripts that build a network without setting a slack bus need one line more."
  },
  {
    "title": "Power flow with the inputs held",
    "date": "2026-11-13",
    "type": "feature",
    "content": "net.calculate_fixed_input_powerflow() solves the equilibrium with the inputs that the components hold (set with comp.set_input), without writing it: the states, the bus voltages, the currents and the Pmech of the generator of the slack bus. It takes Format (\"GUILDAorigin\" for a ResultPF, \"V\", \"powerflow(mat)\" or \"powerflow(tab)\"), Solver (\"newton\", \"levenberg-marquardt\" or \"fsolve\"), Tolerance, MaxIteration, Verbose and WarmStart; the values left out come from GUILDA.setting(\"PowerFlowCalculation\"), and Solver is \"newton\". output.tab_component lists the states X, inputs U and current I of each component. net.initialize(Method=\"FixedInput\") calls it and writes the solution, as before. With Method=\"FixedInput\", an unknown option name now stops with the MATLAB error of an unknown name."
  },
  {
    "title": "Network display methods follow disp_ and plot_",
    "date": "2026-11-13",
    "type": "feature",
    "content": "The display and drawing methods of PowerNetwork are renamed to the verbs of the rest of the API: net.info is now net.disp_summary, net.draw_diagram is now net.plot_diagram, and net.draw_spring_model is now net.plot_spring_model. Options, outputs and behaviour are unchanged. The old names are removed, so scripts that call them need updating."
  },
  {
    "title": "Old initialize options removed",
    "date": "2026-11-13",
    "type": "feature",
    "content": "net.initialize no longer accepts the option methods or the values \"powerflow calculation\", \"optimal powerflow\" and \"calculate from Xequilibrium\", which used to work with a warning. Use Method=\"powerflow\", \"OPF\" or \"equilibrium\". Scripts that still use the old forms now stop with an error."
  },
  {
    "title": "Simulate a scenario by its tag",
    "date": "2026-11-13",
    "type": "feature",
    "content": "A scenario now belongs to one network: sc = net.add_scenario(\"fault\", Time=[0, 10]) creates it, sc.add_fault(...) and the other add_ methods fill it, net.remove_scenario(\"fault\") deletes it, and net.add_scenario(tag, From=sc) copies one. net.simulate(\"fault\") runs one scenario by its tag over its Time; Time=[t0, tend] replaces the time for that call only. The other options (Solver, Tolerance, AbsoluteTolerance, MaxStep, InitialStep, SeparateComplexParts, SampleTime, StopOnOutOfStep, StopAngle, TimeLimit, Progress, Verbose, PlotFcn) come from GUILDA.setting(\"TimeSimulation\"), and an option of the call changes them for that call only. New options: MaxStep and InitialStep for the solver steps, SampleTime for evenly spaced output times, and StopOnOutOfStep with StopAngle to stop when a rotor angle from the generator of the slack bus exceeds the angle (flag 2, output.outOfStep). Format=\"struct\" returns the trajectories as a struct that follows the buses, components and controllers, faster for repeated runs. An input of a scenario is a constant or a time series [t, v] with InputMethod \"zoh\", \"foh\" or \"spline\"; functions are no longer accepted. The verdict is result.judge_out_of_step() and a file is result.export(filename). Removed: Scenario(tag) on its own, several scenarios or a time as positional arguments of simulate, the options SolverOptions and Export of simulate, Options and Judge of a scenario, and sc.judge. Scripts that use these need updating."
  },
  {
    "title": "Scenarios are saved with the network",
    "date": "2026-11-13",
    "type": "feature",
    "content": "PowerNetwork.import_csv and net.export_csv are now PowerNetwork.import and net.export. net.export also writes each scenario of the network to scenario/<tag>.json in the model folder (its Time, Description and disturbances), and PowerNetwork.import adds them back. Scenario.import_csv and Scenario.export_csv are removed. Scripts and network classes that call import_csv or export_csv need updating; folders written before keep working, as they have no scenario folder."
  },
  {
    "title": "One get_sys for every linear model",
    "date": "2026-11-13",
    "type": "feature",
    "content": "The network, a bus, a component, a local controller and a global controller give their linear model with the same method get_sys(point, Name=Value) and the same options (Type, Coordinate, Input, Output, Format), and return [sys, flag, output]. Each model is built from the linear blocks of the components and controllers, connected along the variable map, so the controllers are linearized at the given point and the names are the labels of the variable map. net.linearize is removed: use net.get_sys(), which returns the result object even when flag is false. The Feedback method is removed. Type is \"ODE\" (the default: the bus voltages eliminated) or \"DAE\" (the connected model); it replaces Method and \"Kron\". The network result keeps the DAE: res.Type switches the model of res.A ... res.OutputName without a new linearization, SolverLIN.reduce eliminates the algebraic variables of a DAE, and res.get_contribution(target) gives the part of elements (tags, or classes with their subclasses) in the DAE matrices, the parts of all elements summing to the DAE. The options NonUnit, Algorithm, Controllers, tag, full and con are removed. The point is the first argument: [] (the equilibrium), a vector in the order of obj.get_variable_map(), or {sim, t}; the v3 positional point comp.get_sys(x, V, u) is removed (use comp.get_sys([x; V; u])). A bus or component model has the voltage as input and the current as output. get_variable_map has an Equilibrium column, and the local and global controllers have their own get_variable_map. Scripts that use linearize, Feedback, Method or \"Kron\", or that read the input and output names of a bus or global controller model, need updating."
  },
  {
    "title": "More figures of the power flow result",
    "date": "2026-11-12",
    "type": "feature",
    "content": "The power flow result draws three more figures: res.plot_branch (one bar per branch; Quantity \"P\", \"Q\", \"S\", \"loading\" with the Smax line, or \"loss\"), res.plot_convergence (the largest residual at each iteration on a log scale; Bus adds the |V| of those buses) and res.plot_network (the network with |V| or the angle as node colors and the P or Q flows as arrows; it uses the bus coordinates of the graph parameters, or an automatic layout when a bus has none). Use WarmStart=false to see the iterations of a new calculation."
  },
  {
    "title": "Read the power flow result, and plot_* figures",
    "date": "2026-11-12",
    "type": "feature",
    "content": "The power flow result has views: res.disp_summary() (outcome, totals, |V| range, violations), res.disp_bus (options Bus, Unit=\"SI\" for kV, MW and Mvar, Sort=\"V\"), res.disp_branch (Branch, Unit, Sort=\"loss\" or \"loading\"), res.disp_violation (Class) and res.plot_voltage (Quantity, Limit: the Vmin and Vmax lines). With one output, a disp_ method returns its text. Plot is replaced in every result by a plot_ name: plot_voltage (power flow), plot_dispatch (OPF), plot_pvcurve (continuation power flow), plot_trajectory (simulation) and plot_eigenvalue (linearization). Scripts that call Plot need updating."
  },
  {
    "title": "Choose the output of the power flow",
    "date": "2026-11-12",
    "type": "feature",
    "content": "net.calculate_powerflow takes the option Format for its first output: \"GUILDAorigin\" (default) gives the result object ResultPF, \"V\" gives the complex bus voltages, and \"powerflow(mat)\" and \"powerflow(tab)\" give V, I, P and Q of each bus as a matrix or a table. net.initialize always returns that n-by-4 array of V, I, P and Q, the operating point it writes to the equilibrium, and takes no Format: for a result object, call net.calculate_powerflow or net.calculate_optimal_powerflow. Files are written only by the result: res = net.calculate_powerflow(); res.export(filename). The file method of every result is now export (was Export), e.g. sol.export(\"sim.csv\") after simulate; the analysis option Export of the other analyses keeps its name. The old form calculate_powerflow(\"dynamic\") and the options export, filename and Export of calculate_powerflow are removed: use Solver=\"dynamic\" and res.export."
  },
  {
    "title": "Removed objects are deleted",
    "date": "2026-11-12",
    "type": "feature",
    "content": "Generators, loads, branches, AVRs, PSSs, governors and AGCs are made only with add_component, replace_component, add_branch, add_local_controller and add_global_controller; calling a model class directly, such as controller.avr.AVR_ST1(\"1\"), stops with an error. An object you remove or replace (remove_bus, remove_branch, remove_component, replace_component, remove_local_controller, remove_global_controller, or a controller replaced by add_local_controller) is deleted, together with what was attached to it, so a variable that still holds it can no longer be used. To use it again, add a new one with its key. In a model class of your own, declare the constructor with Access={?Bus} (components), Access={?Component} (local controllers) or Access={?PowerNetwork} (branches and global controllers)."
  },
  {
    "title": "Show the signal connections",
    "date": "2026-11-12",
    "type": "feature",
    "content": "A new command lists, for each input of the components and controllers, the signals that drive it (local, global, observe or equilibrium), grouped by bus, component and controller. The list can be narrowed to one kind of signal or one owner, and returned as text instead of printed."
  },
  {
    "title": "New automatic tag names",
    "date": "2026-11-12",
    "type": "feature",
    "content": "Automatic tags now start with the tag of the parent: a generator on bus B001 is B001SG1 (was SG1B001), its AVR B001SG1CA1 (was CA1SG1B001), and an AGC of the network PowerNetworkAGC1 (was AGC1PowerNetwork). Variable names in the linearized model, the variable map and the time simulation results use the tag of the owner only, e.g. delta_B001SG1 and Vre_B001. Scripts that write tags or variable names by hand need updating."
  },
  {
    "title": "Your own model classes: no bus current argument",
    "date": "2026-11-11",
    "type": "feature",
    "content": "In your own component and controller classes, the model functions no longer take the bus current as an argument. Model classes written for the old arguments need updating."
  },
  {
    "title": "Global controllers connect by input name",
    "date": "2026-11-11",
    "type": "feature",
    "content": "A global controller reads the outputs of the components it controls (their states if they have no outputs) and the voltages of all buses. Each of its outputs drives the input of the same name of a local controller on that component, or else the component input; adding a global controller prints where each output goes. The variable map lists the inputs and outputs of the controllers and these connections. Linearization by the feedback method also works for global controllers that read buses the method eliminates."
  },
  {
    "title": "Change settings from a script",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Settings can now be changed and saved from a script without opening the settings window. After an update of GUILDA, the settings of a category may return to their defaults; GUILDA says so at startup."
  },
  {
    "title": "OPF fixes",
    "date": "2026-10-29",
    "type": "fix",
    "content": "Economic load dispatch, DC OPF and AC OPF run again. Loads keep their power-flow P and Q, and the branch flow sign of DC OPF matches AC OPF."
  },
  {
    "title": "Linearization with every algorithm and several global controllers",
    "date": "2026-10-29",
    "type": "feature",
    "content": "Linearization works with every algorithm (Kron, DAE, feedback) for the bundled generator, load and controller models. Initialization, simulation and linearization accept any number of global controllers."
  },
  {
    "title": "Remove buses and global controllers",
    "date": "2026-10-29",
    "type": "feature",
    "content": "Buses can now be removed from a network, optionally together with their branches, and so can global controllers. Marking a bus as the slack bus makes it the only slack bus."
  },
  {
    "title": "Simulation event fixes",
    "date": "2026-10-29",
    "type": "fix",
    "content": "A simulation runs without events, stays within the requested time range, and applies input and state offset events correctly, also when they start after time zero."
  },
  {
    "title": "Start GUILDA in batch mode",
    "date": "2026-10-29",
    "type": "feature",
    "content": "GUILDA starts in MATLAB batch mode. The tutorial opens only when the MATLAB desktop is available."
  },
  {
    "title": "More OPF fixes and MATPOWER export",
    "date": "2026-10-29",
    "type": "fix",
    "content": "AC OPF solves with branch current and power limits and with linear-only costs. A network can now be converted into a MATPOWER case."
  },
  {
    "title": "IEEE 14-bus network matches MATPOWER case14",
    "date": "2026-10-29",
    "type": "model",
    "content": "The IEEE 14-bus network has the line charging, load reactive power, voltage and generator limits and generator costs of MATPOWER case14, so its results change. A new variant has every transformer tap set to 1. CSV import keeps transformer taps."
  },
  {
    "title": "Uniform analysis results and per-call options",
    "date": "2026-10-29",
    "type": "feature",
    "content": "Power flow, OPF, continuation power flow, simulation and linearization all return a result, a success flag and further details; the result can be plotted and exported. Options such as the method, tolerance and message level apply to one call. Scripts that read the old outputs need updating."
  },
  {
    "title": "Continuation power flow",
    "date": "2026-10-29",
    "type": "feature",
    "content": "The continuation power flow computes PV curves for chosen load buses, which can be plotted, the maximum loading and the nose point. The old continuation power flow function still works but is deprecated."
  },
  {
    "title": "Simulation options",
    "date": "2026-10-29",
    "type": "feature",
    "content": "The time simulation takes options for the solver, tolerances, a time limit, progress display, messages, plotting and export. Its success flag is 1 when the run completed, 0 when the time limit stopped it and -1 when the solver stopped; scripts that tested it for an early stop need updating."
  },
  {
    "title": "Full linearized model and the variable map",
    "date": "2026-10-29",
    "type": "feature",
    "content": "A new command gives the full linearized model, which can be reduced by the Kron, feedback or DAE method, at a given state or at a time of a simulation. The variable map shows the variable order. Linearization returns the system, a success flag and further details."
  },
  {
    "title": "Network import and export",
    "date": "2026-10-29",
    "type": "feature",
    "content": "Networks can be imported from and exported to CSV folders, and imported from MATPOWER cases without MATPOWER installed. Older CSV folders still import."
  },
  {
    "title": "New IEEE 9-bus and 68-bus networks",
    "date": "2026-10-30",
    "type": "model",
    "content": "New IEEE 9-bus (WSCC 3-machine) and 68-bus (16-machine NETS-NYPS) networks with one-axis generators, impedance loads and an AVR and PSS on every generator. They can also be built without the AVRs and PSSs."
  },
  {
    "title": "Lossless IEEE 14-bus network follows case14",
    "date": "2026-10-30",
    "type": "model",
    "content": "The lossless IEEE 14-bus network is the IEEE 14-bus network with every branch resistance set to 0, keeping line charging, the bus shunt and the transformer taps. Its results change."
  },
  {
    "title": "Automatic tags are unique",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Adding buses, branches and components no longer repeats a tag after a removal. Adding a global controller with a tag already in use is an error."
  },
  {
    "title": "Controller fixes",
    "date": "2026-10-30",
    "type": "fix",
    "content": "After adding or replacing an AVR or PSS, initialize the network again. Replacing an AVR keeps its PSS. Trip events that name a global controller or a component with local controllers act on the right states."
  },
  {
    "title": "Clearer simulation event errors",
    "date": "2026-10-30",
    "type": "feature",
    "content": "Simulation disturbances are checked before the run, and an invalid input name or value stops with an error that lists the valid inputs. A disturbance entirely outside the simulation time gives a warning."
  },
  {
    "title": "Smaller fixes",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Linearization works with buses that have no components. The GUILDA dictionary works from any current folder and no longer lists archived classes."
  },
  {
    "title": "Simulations of large networks at rest",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Simulations that start at rest no longer stop at time zero in large networks such as the IEEE 68-bus network without local controllers. When the solver stops, the message names the phase and its time interval."
  },
  {
    "title": "OPF load cost and DC branch susceptance",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Loads have no OPF cost by default, so the OPF cost is the generation cost. DC OPF uses the MATPOWER branch susceptance with taps and phase shifts, which changes DC OPF results for such branches."
  },
  {
    "title": "Controller inputs by name and the local LQR controller",
    "date": "2026-10-30",
    "type": "feature",
    "content": "A local controller reads the outputs or states of its component by the names of its inputs; the input names Xall and Yall read all states or all outputs. The local LQR controller works again in place of an AVR, with its gain computed from Q and R at initialization."
  },
  {
    "title": "Same linearized model layout for components and buses",
    "date": "2026-10-30",
    "type": "feature",
    "content": "The linearized models of a component and of a bus order the inputs as port, component inputs, then controller inputs, and the outputs likewise. States are no longer outputs, so scripts that read states from these outputs need updating."
  },
  {
    "title": "Simulation results by variable",
    "date": "2026-10-30",
    "type": "feature",
    "content": "Simulation results follow the order of the variable map, including controller states. The state at a given time can be taken from a result, and linearization at a time of a simulation works with controllers."
  },
  {
    "title": "Initialization returns a result",
    "date": "2026-10-30",
    "type": "feature",
    "content": "Initialization returns a result, a success flag and further details, and can start from the power flow, the OPF or the equilibrium. A failed power flow or OPF is an error and leaves the network unchanged. Scripts that read a flag and a table from it need updating (the bus table of the result is the old table)."
  },
  {
    "title": "Buses without states detected automatically",
    "date": "2026-11-02",
    "type": "feature",
    "content": "Linearization finds buses without states by itself, so the setting that marked them is no longer needed; it still works with a warning."
  },
  {
    "title": "Incomplete simulations keep their results",
    "date": "2026-11-02",
    "type": "feature",
    "content": "When a simulation does not complete, it warns and returns the completed phases with a flag of -1 instead of an error. The time limit covers the whole run. Large networks are simulated with sparse matrices."
  },
  {
    "title": "Simulation and initialize fixes",
    "date": "2026-11-02",
    "type": "fix",
    "content": "A generator with a local controller can trip. An input event on an input driven by a local controller adds to its output. Initialization from the OPF or the equilibrium sets a consistent operating point or stops with an error."
  },
  {
    "title": "New IEEJ standard networks",
    "date": "2026-11-04",
    "type": "model",
    "content": "New IEEJ EAST10, EAST30, WEST10 and WEST30 networks, the IEEJ standard power system models with the report's generators, exciters and governors. Options select the peak or night power-flow case and leave out the governors or the local controllers. See each class help for the conversions."
  },
  {
    "title": "Simulation scenarios",
    "date": "2026-11-04",
    "type": "feature",
    "content": "Describe the disturbances of a simulation as a scenario: add faults, trips, branch openings, offsets and inputs, then add the scenario to the network or simulate it directly. A scenario gives a stability verdict for a result, and scenarios can be read and written as CSV."
  },
  {
    "title": "Old simulation events replaced by scenarios",
    "date": "2026-11-04",
    "type": "feature",
    "content": "The old simulation event object still works and returns a scenario, with a warning. Use scenarios in new scripts."
  },
  {
    "title": "Open branches during a simulation",
    "date": "2026-11-04",
    "type": "feature",
    "content": "A scenario can open branches for a time interval during a simulation and reconnect them at its end."
  },
  {
    "title": "Governors and IEEJ governor models",
    "date": "2026-11-04",
    "type": "model",
    "content": "A component can have a governor beside its AVR. New IEEJ governor models LPT1 (thermal and nuclear), LPT3 and LPT4 (hydro)."
  },
  {
    "title": "DC1 AVR field voltage limit",
    "date": "2026-11-04",
    "type": "model",
    "content": "The DC1 AVR takes an upper and a lower field voltage, a field voltage limit without windup. The defaults give the same results as before."
  },
  {
    "title": "Park generator with equal transient and synchronous reactances",
    "date": "2026-11-04",
    "type": "fix",
    "content": "The Park generator model computes its equilibrium when the q-axis transient reactance equals the q-axis synchronous reactance (or likewise on the d axis), so a machine without a q-axis transient circuit can be modeled."
  },
  {
    "title": "Verification against published results",
    "date": "2026-11-04",
    "type": "feature",
    "content": "The folder _GUILDAverification compares bundled networks with their literature: the reference, the cases as scenario CSV files, the published verdicts and a comparison script. It covers the four IEEJ networks."
  },
  {
    "title": "Unused tools functions removed",
    "date": "2026-11-05",
    "type": "feature",
    "content": "Several unused helper functions and one helper package of the tools folder are removed. Scripts that call them need their own copy."
  },
  {
    "title": "Initialization updates the model after edits",
    "date": "2026-11-06",
    "type": "feature",
    "content": "After editing parameters or the topology, initialize the network again: it recomputes only what the edits affect. Simulation, linearization and the continuation power flow stop with an error naming the edits until it has run."
  },
  {
    "title": "Edit parameters in the parameter table",
    "date": "2026-11-06",
    "type": "feature",
    "content": "Read and edit model parameters in the parameter table of each model (columns dynamics, powerflow, operation, OPF, graph, base). The separate parameter properties are removed: scripts that use them switch to the parameter table. The frequency and system base are in the base column of the network's table."
  },
  {
    "title": "OPF costs and constraints of your own",
    "date": "2026-11-07",
    "type": "feature",
    "content": "The OPF takes cost and constraint functions of your own, added to the problem, and returns the duals of named constraints in its result. It can also solve an OPF problem built from the network and then changed by the user."
  },
  {
    "title": "Power flow without toolboxes",
    "date": "2026-11-07",
    "type": "feature",
    "content": "The power flow algorithm can be Newton (default), gradient, Levenberg-Marquardt, dynamic or fsolve; only fsolve needs Optimization Toolbox, so the power flow runs with MATLAB alone. The former algebraic choice is now fsolve. The option that chooses the algorithm was renamed on 2026-11-10."
  },
  {
    "title": "Linearization without Control System Toolbox",
    "date": "2026-11-07",
    "type": "feature",
    "content": "Linearization returns a result with the matrices A, B, C, D, E and the variable names, or a struct, without any toolbox. Scripts that apply state-space functions to it, such as eigenvalues, step responses or poles, request the state-space model output, which needs Control System Toolbox."
  },
  {
    "title": "Optional toolboxes and the startup check",
    "date": "2026-11-07",
    "type": "feature",
    "content": "GUILDA needs MATLAB only. OPF and the fsolve power flow algorithm need Optimization Toolbox; state-space model output and the LQR controllers need Control System Toolbox. The startup prints for each toolbox \"ok\" or the features unavailable without it; Getting Started has the full table."
  },
  {
    "title": "Show a model in a GUI",
    "date": "2026-11-07",
    "type": "feature",
    "content": "A window can be opened for a network, bus, branch, component or controller with its parameters (editable in place), its equilibrium, a breadcrumb and cards of the children to move between models, and a Docs button for the reference page of the class. The window can also be placed in a panel or tab of your own app, and a new model class needs no extra code."
  },
  {
    "title": "Solver chooses the algorithm",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Every analysis chooses its numerical algorithm with the Solver option, e.g. Levenberg-Marquardt for the power flow, and initialization passes it on to the power flow or the OPF. Scripts and saved settings that use the Method option for the power flow algorithm switch to Solver. Method now says what is built: for linearization it chooses Kron, feedback or DAE (the old Algorithm option still works, with a warning)."
  },
  {
    "title": "Equilibrium with the inputs held",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The inputs of a component at the equilibrium can now be set, and initialization with these inputs held finds the states and bus voltages; the first generator of the slack bus balances the power. Until then, the analyses and the default initialization stop with an error, and initialization from the power flow discards the edited inputs. The separate impedance and power properties of loads are removed: scripts that read them use the equilibrium inputs of the load instead."
  },
  {
    "title": "Operating limits in the continuation power flow",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The continuation power flow can apply the operating limits of the parameter table along the path: reactive power, bus voltage and branch apparent power. With the reactive power limit, a PV bus whose generators reach their total minimum or maximum becomes a PQ bus at that bound and the trace goes on; with the voltage or branch limit, the trace stops at the first point that reaches it. Tables in the result show where this happened. All three limits can be applied at once; by default none is."
  },
  {
    "title": "Limit violations of the power flow",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The power flow result has a table of the operating limits of buses, branches and components that the solution violates, one row per limit, with no rows when there is none. The power flow itself does not apply the limits."
  },
  {
    "title": "Power flow tolerance and warm start",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The default power flow tolerance is 1e-8, the largest P/Q mismatch in pu, with the same meaning for every algorithm; change the default in the power flow section of the settings. The power flow starts from the last solution of the network (a flat start can be requested), so repeated runs with small changes need fewer iterations. The bus parameters for the initial voltage magnitude and angle are removed: scripts that set them need updating."
  },
  {
    "title": "Tags must be valid variable names",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Every tag of a network, bus, branch, component or controller, including the tags in CSV data, must be a valid MATLAB variable name: a letter first, then letters, digits and underscores. Any other tag stops with an error. The branches of the IEEJ WEST10 network are renamed like LINE20_1 and G1_TR (were LINE20-1 and G1-TR), and its AC OPF now solves."
  },
  {
    "title": "Analysis defaults in the settings",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The defaults of every analysis (power flow, OPF, continuation power flow, time simulation, linearization) are set in the GUILDA settings; an option given in a call changes them for that call. The solver properties of a network, such as the time simulation tolerance or the OPF method, can no longer be set: give the option in the call instead. The network still keeps the OPF costs, constraints, default cost and reference bus, and the load buses of the continuation power flow. The tolerance (OPF, time simulation) and the iteration limit (continuation power flow) settings are renamed. The plot option is removed: draw from the result instead."
  },
  {
    "title": "Watch an analysis while it runs",
    "date": "2026-11-10",
    "type": "feature",
    "content": "A new option shows the progress of an analysis in a figure: the residual of each power flow equation at every iteration, the MATLAB optimization plots of the AC OPF or the fmincon algorithm, or the PV curves of all buses growing at each step of the continuation power flow. A plot function of your own, written as for MATLAB optimization, can also be given and can stop the analysis. The OPF display setting is replaced by a message setting (off by default)."
  },
  {
    "title": "Renamed setting keys",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Each setting key now has the name of the matching option, and a setting of one solver is named after the solver and its MATLAB option, e.g. FminconAlgorithm or FsolveMaxFunctionEvaluations. NaN means automatic (the iteration limit and gradient step size of the power flow, where 0 meant automatic), and on/off settings are true/false. The power flow has a new message setting. Saved values of renamed keys return to the default; change a saved iteration limit or gradient step size of 0 to NaN."
  }
];
