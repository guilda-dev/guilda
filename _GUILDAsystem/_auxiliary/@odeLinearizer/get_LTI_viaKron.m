function [Ax_ode, Bx_ode, Cx_ode, Dx_ode] = get_LTI_viaKron(obj)           
                      
    net   = obj.odeNetwork;
    bus   = net.a_Bus;          
    n_bus = numel(bus);
    
    Ax = cell(n_bus,1);
    Bv = cell(n_bus,1);
    Bu = cell(n_bus,1);
    Cx = cell(n_bus,1);
    Dv = cell(n_bus,1);
    Du = cell(n_bus,1);
    
    InputNames  = cell(n_bus,1);
    StateNames  = cell(n_bus,1);

    InputGroup  = cell(n_bus,1);
    OutputGroup = cell(n_bus,1);

              
    for i_bus = 1:n_bus
        a_comp = bus{i_bus}.a_Component;
        n_com = numel(a_comp);
        
        Axi = cell(1,n_com);
        Bvi = cell(1,n_com);
        Bui = cell(1,n_com);
        Cxi = cell(1,n_com);
        Dui = cell(1,n_com);
        Dvi = zeros(2,2);


        InputNames_i  = cell(n_com,1);
        StateNames_i  = cell(n_com,1);

        InputGroup_i  = cell(n_com,1);
        OutputGroup_i = cell(n_com,1);

        for i_com = 1:n_com
            a_compi = a_comp{i_com};
            sslin   = a_compi.odeLinearSystem;
            lv_Bv   = ismember(fieldnames(sslin.InputGroup), ["Vre","Vim"]+"_"+a_compi.str_tag);                       
            Axi{i_com} = sslin.A;
            Bvi{i_com} = sslin.B(:, lv_Bv);
            Bui{i_com} = sslin.B(:,~lv_Bv);
            Cxi{i_com} = sslin.C;
            Dui{i_com} = sslin.D(:,~lv_Bv);
            Dvi = Dvi + sslin.D(:, lv_Bv);

            str_x = a_compi.str_x;
            str_u = a_compi.str_u;

            StateNames_i{i_com}  = a_compi.attach_tag(str_x);
            InputNames_i{i_com}  = a_compi.attach_tag(str_u);
            
            InputGroup_i{i_com}  = [str_u,repmat("u"+i_com, numel(str_u), 1)];
            OutputGroup_i{i_com} = [str_x,repmat("x"+i_com, numel(str_x), 1)];
        end

        Ax{i_bus} = blkdiag(Axi{:});
        Bv{i_bus} = vertcat(Bvi{:}); 
        Bu{i_bus} = blkdiag(Bui{:});
        Cx{i_bus} = horzcat(Cxi{:});
        Du{i_bus} = horzcat(Dui{:});
        Dv{i_bus} = Dvi;

        StateNames{i_bus} = vertcat(StateNames_i{:});
        InputNames{i_bus} = vertcat(InputNames_i{:});

        InputGroup{i_bus}  = vertcat(InputGroup_i{:});
        OutputGroup{i_bus} = vertcat(OutputGroup_i{:});
    end

    Ymat = obj.odeNetwork.get_admittance_matrix;
    Ymat = tools.complex2matrix( Ymat.Variables );
           
    Ax_dae = blkdiag(Ax{:});
    Bv_dae = blkdiag(Bv{:}); 
    Bu_dae = blkdiag(Bu{:});
    Cx_dae = blkdiag(Cx{:});
    Du_dae = blkdiag(Du{:});
    Dv_dae = blkdiag(Dv{:}) - Ymat;
    
    mat_v2x = Bv_dae / Dv_dae;
    
    n_x = size(Ax_dae,1); 
    n_u = size(Bu_dae,2);

    Ax_ode = Ax_dae - mat_v2x * Cx_dae;
    Bx_ode = Bu_dae - mat_v2x * Du_dae;
    Cx_ode = eye(n_x);
    Dx_ode = zeros(n_x,n_u);


    sys = ss(Ax_ode, Bx_ode, Cx_ode, Dx_ode);
    sys.InputName  = vertcat(InputNames{:});
    sys.StateName  = vertcat(StateNames{:});
    sys.OutputName = sys.StateName;

    sys.InputGroup  = build_group_struct(vertcat(InputGroup{:}));
    sys.OutputGroup = build_group_struct(vertcat(OutputGroup{:}));

    obj.odeLinearSystem = sys;
end

function sct_group = build_group_struct(group_names)
    sct_group = struct();
    n_row     = size(group_names, 1);
    all_names = cellstr(string([group_names(:,1); group_names(:,2)]));
    all_index = [(1:n_row)'; (1:n_row)'];

    [unique_names, ~, ic] = unique(all_names);
    for i = 1:numel(unique_names)
        sct_group.(unique_names{i}) = all_index(ic == i).';
    end
end