function net = import_MATPOWER(results)
    
    mat_bus     = results.bus;
    mat_branch  = results.branch;
    mat_gen     = results.gen;
    mat_gencost = results.gencost;
    
    baseMVA = results.baseMVA;
    
    net = PowerNetwork();
    
    for i_bus = 1:size(mat_bus,1)
        type     = mat_bus( i_bus,       2 );
        PQload   =-mat_bus( i_bus, [ 3, 4] ) / baseMVA;
        shunt    = mat_bus( i_bus, [ 5, 6] );
        Vinit    = mat_bus( i_bus, [ 9, 8] );
        baseKV   = mat_bus( i_bus,      10 );
        Vminmax  = mat_bus( i_bus, [13,12] );

        Busi = Bus(shunt, ...
                 "baseKV"      , baseKV     , ...
                 "V_minmax"    , Vminmax    , ...
                 "V_init"      , Vinit      , ...
                 "PQshunt_max" , [ inf,inf] , ...
                 "theta_minmax", [-pi ,pi ] );

        

        ivec_gen = find(mat_gen(:,1) == i_bus);
        for i_gen = ivec_gen(:)'
            mBase   = mat_gen(i_gen,      7 );
            Qminmax = mat_gen(i_gen, [ 5, 4]) / mBase;
            Vg      = mat_gen(i_gen,      6 );
            status  = mat_gen(i_gen,      8 );
            Pminmax = mat_gen(i_gen, [10, 9]) / mBase;

            Pg      = mean(Pminmax);
            Qg      = mean(Qminmax);

            StartupCost = mat_gencost(i_gen, [2,3]);
            PowerCost   = mat_gencost(i_gen, [5,6]);

            Geni = component.generator.park();
            Geni.parameter.OPF{1,["P_min","P_max","Q_min","Q_max","P0","Q0","startup","shutdown","HP","fP"]} = [Pminmax,Qminmax,Pg,Qg,StartupCost,PowerCost];
            
            if type==3
                Geni.parameter.powerflow{1,["theta","V","P","Q"]} = [ 0,Vg,nan,nan];
            else
                Geni.parameter.powerflow{1,["theta","V","P","Q"]} = [nan,Vg,Pg,nan];
            end
            
            if status==0
                Geni.isConnected = false;
            end

            Busi.add_component(Geni);
        end

        if ~all(PQload==0) %|| isempty(Busi.Components)
            Loadi = component.load.power();
            Loadi.parameter.powerflow{1,["P","Q"]} = PQload;
            Loadi.parameter.OPF{1,["P_min","Q_min","P_max","Q_max","P0","Q0"]} = [PQload,PQload,PQload];
            Busi.add_component(Loadi)
        end

        net.add_bus(Busi);
        
    end

    for i_branch = 1:size(mat_branch,1)
        from     = mat_branch( i_branch,       1 );
        to       = mat_branch( i_branch,       2 );
        x        = mat_branch( i_branch,   [3,4] );
        y        = mat_branch( i_branch,       5 );
        Pmax     = mat_branch( i_branch,       6 ) / baseMVA;
        tap      = mat_branch( i_branch,       9 );
        phase    = mat_branch( i_branch,      10 );
        status   = mat_branch( i_branch,      11 );
        arg_min  = mat_branch( i_branch,      12 ) / 180 * pi;
        arg_max  = mat_branch( i_branch,      13 ) / 180 * pi;

        
        if (tap == 0 && phase == 0)
            Branchi = branch.pi(x,y);

        else
            Branchi = branch.pi_transformer(x,y,tap,phase);
        end

        if ( status == 0)
            Branchi.isConnected = Flase;
        end

        Branchi.parameter.OPF{1,["P_max","arg_min","arg_max"]} = [Pmax,arg_min,arg_max];

        net.add_branch(Branchi,from,to);
    end
    
    net.initialize;
end