function info(obj, opt)
    arguments
        obj 
        opt.equilibrium(1,1) logical = true
        opt.parameter  (1,1) logical = true
        opt.bus        (1,1) logical = true
        opt.branch     (1,1) logical = true
        opt.component  (1,1) logical = true
    end
    net = obj.struct();

    
    bar  = string(repmat('=',1,100));
    sep  = @(s) disp( newline+bar+newline+"  "+s+newline+bar+newline);
    list = @(c) string([' ',tools.hcellfun(@(ci) [char(ci.str_tag),' '], c)]);

    a_Bus = net.a_Bus;
    a_Bra = net.a_Branch;
    a_Com = tools.vcellfun(@(b) b.a_Component, net.a_Bus);

    n_Bus = numel(a_Bus);
    n_Bra = numel(a_Bra);
    n_Com = numel(a_Com);
    
    sep("Summary")
    disp("Total Buses: "      + n_Bus);
    disp("Total Branches: "   + n_Bra);
    disp("Total Components: " + n_Com);

    if opt.bus
        tab_bus  = cell2tab(a_Bus);
        
        Tag = tab_bus{:,'str_tag'};
        Component = tools.vcellfun(@(c) list(c), tab_bus.a_Component);
        tab_disp = table(Tag, Component);

        if opt.parameter
            bustype   = tab_bus.str_bustype;
            Parameter = [table(bustype), tab_bus.tab_parameter];
            tab_disp  = [tab_disp, table(Parameter)];
        end
        if opt.equilibrium
            cv_Vst = tab_bus.c_Vequilibrium;
            theta  = angle(cv_Vst);
            V = abs(cv_Vst);
            S = cv_Vst .* conj(tab_bus.c_Iequilibrium);
            P = real(S);
            Q = imag(S);
            Equilibrium = table(theta,V,P,Q);
            tab_disp  = [tab_disp, table(Equilibrium)];
        end
        sep("Bus")
        disp(tab_disp);
    end

    if opt.branch
        [str_cls, cell_tab] = separate(a_Bra);

        sep("Branch")
        for i_cls = 1:numel(str_cls)
            tab_bra  = cell_tab{i_cls};
            
            Tag   = tab_bra{:,'str_tag'};
            from = tools.vcellfun(@(c) string(c{1}), tab_bra.a_Bus);
            to   = tools.vcellfun(@(c) string(c{2}), tab_bra.a_Bus);
            Bus  = table(from,to);
            tab_disp = table(Tag,Bus);
    
            if opt.parameter
                Parameter = tab_bra.tab_parameter;
                tab_disp  = [tab_disp, table(Parameter)]; %#ok
            end
            disp(newline+" << "+str_cls(i_cls)+" >>"+newline)
            disp(tab_disp);
        end
    end

    if opt.component
        [str_cls, cell_tab] = separate(a_Com);

        sep("Component")
        for i_cls = 1:numel(str_cls)
            tab_com  = cell_tab{i_cls};
            
            Tag   = tab_com{:,'str_tag'};
            Bus   = tab_com.a_Bus;
            Controller = tools.vcellfun(@(c) list(c), tab_com.a_LocalController);
            tab_disp = table(Tag,Bus,Controller);
    
            if opt.parameter
                Parameter = tab_com.tab_parameter;
                tab_disp  = [tab_disp, table(Parameter)]; %#ok
            end
            if opt.equilibrium
                cv_Vst = tab_com.c_Vequilibrium;
                theta  = angle(cv_Vst);
                V = abs(cv_Vst);
                S = cv_Vst .* conj(tab_com.c_Iequilibrium);
                P = real(S);
                Q = imag(S);
                PowerFlow = table(theta,V,P,Q);

                sv_x    = tab_com{1,"sv_x"};
                State    = array2table( tools.vcellfun(@(x) x(:).', tab_com.rv_Xequilibrium), "VariableNames", sv_x{1});

                sv_u    = tab_com{1,"sv_u"};
                Input    = array2table( tools.vcellfun(@(x) x(:).', tab_com.rv_Uequilibrium), "VariableNames", sv_u{1});
                
                Equilibrium = table(PowerFlow,State,Input);
                tab_disp = [tab_disp, table(Equilibrium)]; %#ok
            end
            disp(newline+" << "+str_cls(i_cls)+" >>"+newline)
            disp(tab_disp);
        end
    end

end

function [str_cls, cell_tab] = separate(cell_cls)
    str_cls = tools.vcellfun(@(c) string(c.class), cell_cls);
    [str_cls, ~, i_cls] = unique(str_cls);
    
    cell_tab = cell(numel(str_cls),1);
    for i = 1:numel(str_cls)
        cell_tab{i} = cell2tab(cell_cls(i_cls==i));
    end
end



function tab = cell2tab(cell_cls)
    str_fd = tools.hcellfun(@(c) fieldnames(c), cell_cls);
    str_fd = unique(str_fd);

    n_fd  = numel(str_fd);
    n_cls = numel(cell_cls);

    sct_cls(n_cls) = struct();
    for i_cls = 1:n_cls
        a_clsi  = cell_cls{i_cls};
        for i_fd = 1:n_fd
            str_fdi = str_fd{i_fd};
            if isfield( a_clsi, str_fdi)
                if iscell(a_clsi.(str_fdi))
                    sct_cls(i_cls).(str_fdi) = {a_clsi.(str_fdi)};
                else
                    sct_cls(i_cls).(str_fdi) = a_clsi.(str_fdi);
                end
            else
                sct_cls(i_cls).(str_fdi) = [];
            end
        end
    end

    tab = struct2table(sct_cls, "AsArray",true);
end