function OutPlot_for_app(app)
para_list = {'delta','omega','E','Vfd','xi','AGC'...
            'Vabs','Vangle','Iabs','Iangle','P','Q','W'};
para_idx = [app.delta.Value;...
            app.omega.Value;
            app.E.Value;
            app.Vfd.Value;
            app.controller.Value;
            app.globalcontroller.Value;
            app.Vabs.Value;
            app.Varg.Value;
            app.Iabs.Value;
            app.Iarg.Value;
            app.P.Value;
            app.Q.Value;
            app.Storagefunction.Value];
para = para_list(para_idx);
if app.allbusButton.Value
    idx = 1:numel(app.net.a_bus);
elseif app.onlygenbusButton.Value
    temp = simulation.net_info.look_component_type(app.net);
    idx = find(temp.has_state);
elseif app.onlyloadbusButton.Value
    temp = simulation.net_info.look_component_type(app.net);
    idx = find(temp.load);
elseif app.specifyButton.Value
    txt = app.specifyidx.Value;
    idx = str2num(txt);
    if numel(idx)==0
        switch app.LanguageSwitch.Value
            case '日本語'
                error('母線の番号が指定されていません')
            case 'English'
                error('Bus idx number is not specified')
        end
    end
end

temp_position = app.GUILDA_GUIsimulator.Position;
temp_position([1,2]) = temp_position([1,2])+5;
temp_position(3) = temp_position(3)-10;
temp_position(4) = temp_position(4)*0.85;

simulation.out_fuctory.plot_out(app.out,app.net,para,idx,...
                'legend_switch',app.legend_switch.Value,...
                'mode_disp_command',app.switch_output_command.Value,...
                'position',temp_position);
end