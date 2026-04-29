function [powerflow_bus,flag,output] = solve(obj, net, mode, opt)
    arguments
        obj
        net 
        mode    (1,1) string {mustBeMember(mode,["algebraic","dynamic"])} = "algebraic"
        opt.export  (1,1) logical = mode=="dynamic";
        opt.filename(1,1) string  = string(datetime("now","Format","uuMMdd_HHmmss"))+"_PFcalculation.json"
    end
 
    tab_Ymat  = net.get_admittance_matrix;
    tab_PFset = tools.vcellfun(@(b) b.get_pf_set, net.a_Bus);
    str_Bus   = tab_PFset.Properties.RowNames;
    cm_Y      = tab_Ymat{str_Bus,str_Bus};

    switch mode
        case "algebraic"
            [cv_Vbus,flag,output] = obj.solve_algebraic(cm_Y, tab_PFset);
        case "dynamic"
            [cv_Vbus,flag,output] = obj.solve_dynamic(cm_Y, tab_PFset);
    end

    % Vbus -> Ibus -> Pbus,Qbus
    cv_Ibus = cm_Y*cv_Vbus;
    cv_Sbus = cv_Vbus .* conj(cv_Ibus);
        
    % convert double->table
    str_bus = tab_PFset.Properties.RowNames;
    powerflow_bus = array2table(...
        [angle(cv_Vbus),abs(cv_Vbus),real(cv_Sbus),imag(cv_Sbus),cv_Vbus,cv_Ibus], ...
        "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"],"RowNames",str_bus);


    % export json each step value
    if opt.export
        n_Bus    = size(tab_PFset,1);

        out = struct();
    
        l_slack = tab_PFset.Type'=="slack";
        l_PV    = tab_PFset.Type'=="PV";
        l_PQ    = tab_PFset.Type'=="PQ";

        out.Text =   n_Bus+"Bus Model" +newline + ...
                     " > slack : "              + mat2str(find(l_slack)) + newline + ...
                     " > PV ("+sum(l_PV)+") : " + mat2str(find(l_PV))    + newline +...
                     " > PQ ("+sum(l_PQ)+") : " + mat2str(find(l_PQ))    ;

        out.nodes(n_Bus) = struct('Color',[], 'Label',[], 'Hover',[], ...
                                  'Varg' ,[], 'Vabs' ,[] );


        cr_Vbus = obj.rm_response(2:2:end,:) .* exp( 1j* obj.rm_response(1:2:end,:) );
        cr_Ibus = cm_Y * cr_Vbus;
        cr_Sbus = cr_Vbus .* conj(cr_Ibus);
        rr_Pflow = -real(cr_Sbus);
        rr_Iflow = -imag(cr_Sbus) ./ obj.rm_response(2:2:end,:);



        for i_bus = 1:n_Bus
            tab_i = tab_PFset(i_bus,:);
    
            type = tab_i.Type;
            h = "Bus"+i_bus+" ("+type+")"+newline;
            p = nan;
            q = nan;
            switch type
                case "PV"
                    c = [0,1,0,1];
                    p = {tab_i.P};
                    h = h+"P="+tab_i.P+", V="+tab_i.V;
                case "PQ"
                    c = [1,0,0,1];
                    p = {tab_i.P};
                    q = {tab_i.Q};
                    h = h+"P="+tab_i.P+", Q="+tab_i.Q;
                case "slack"
                    c = [0,0,1,1];
                    h = h+"Varg="+tab_i.Varg+", V="+tab_i.V;
                otherwise
                    c = [0,0,0,1];
            end
            l = num2str(i_bus);

            if mode == "dynamic" && obj.dynamic.foh_PQ~=0
                scale = min( obj.rr_step/obj.dynamic.foh_PQ, 1);
                if iscell(p); p = p{1}*scale; end
                if iscell(q); q = q{1}*scale; end
            end

            out.nodes(i_bus).Color = c;
            out.nodes(i_bus).Label = l;
            out.nodes(i_bus).Hover = h;
            out.nodes(i_bus).Pset  = p;
            out.nodes(i_bus).Qset  = q;
            out.nodes(i_bus).Pflow = rr_Pflow(i_bus,:);
            out.nodes(i_bus).Iflow = rr_Iflow(i_bus,:);
            out.nodes(i_bus).Varg  = obj.rm_response(2*i_bus-1,:);
            out.nodes(i_bus).Vabs  = obj.rm_response(2*i_bus  ,:);

        end
        g = graph(abs(cm_Y),'omitselfloops');
        out.edges = reshape(g.Edges.EndNodes.', [], 1).';
    
        jsonStr = jsonencode(out,"PrettyPrint",true);
        outFile = char(opt.filename);
        if ~strcmp(outFile( (end-4):end ), '.json')
            outFile = opt.filename + ".json";
        end
        outPath = fullfile(GUILDA.pwd, "_GUILDAexport");
        if ~isfolder(outPath)
            mkdir(outPath)
        end
        fid     = fopen(fullfile(outPath,outFile), 'w'); 
        fwrite(fid, jsonStr, 'char'); 
        fclose(fid);

        disp("<INFO>")
        disp("  Exported json file: _GUILDAexport/"+ outFile);
        disp("  You can upload this json file to the following link to visualize the calculation process.");
        fprintf('  <a href="https://ta-nish18.github.io/GridSpring/">https://ta-nish18.github.io/GridSpring/</a>\n\n')
    end


    % Notify
    if flag<=0
        str_warnFlag = obj.WhenFailed;
        if str_warnFlag=="SYSTEM DEFAULT"
            struct_default = GUILDA.config("EnvFsolve");
            str_warnFlag = struct_default.WhenFailed;
        end
        switch str_warnFlag
        case "WARN" ; warning(output.message)
        case "ERROR"; error(output.message)
        case "DISP" ; disp(output.message)
        case "NONE" ; return
        end
    end

end