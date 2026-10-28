function bra = add_branch(obj, Type, from_to, opt)
    arguments
        obj 
        Type         (1,:) char {mustBeMember(Type,{'T','pi','pi_transformer','two_winding_transformer'})}
        from_to      (1,2) {string,double}   = [1,2]
        opt.R        (1,1) double = 0;
        opt.X        (1,1) double = 1;
        opt.C        (1,1) double = 0;
        opt.Tap      (1,1) double = 1;
        opt.Phase    (1,1) double = 0 /180*pi;
        opt.Smax     (1,1) double = inf;
        opt.Imax     (1,1) double = inf;
        opt.Pmax     (1,1) double = inf;
        opt.Qmax     (1,1) double = inf;
        opt.Vargmax  (1,1) double = 90/180*pi;
        opt.MidXaxis     (1,:) string = [];
        opt.MidYaxis     (1,:) string = [];
        opt.Marker       (1,1) string = "-";
    end

    % a_Busの番号で指定された場合
    if isnumeric(from_to)
        a_Bus = obj.a_Bus(from_to);
    else
        str_Bus = string(obj.a_Bus)';
        [~,ir_bus] = ismember(from_to, str_Bus);
        
        assert(ir_bus(1),"Bus class '"+from_to(1)+"' not found.")
        assert(ir_bus(2),"Bus class '"+from_to(2)+"' not found.")
        
        a_Bus = obj.a_Bus(ir_bus);
    end

    n_Branch  = numel(obj.a_Branch);
    str_Index = num2str(n_Branch+1,"%.3d");

    % Build Instance
    switch Type
        case 'T';                       mkInst = @branch.T;
        case 'pi';                      mkInst = @branch.pi;
        case 'pi_transformer';          mkInst = @branch.pi_transformer;
        case 'two_winding_transformer'; mkInst = @branch.two_winding_transformer;

    end
    bra = mkInst(str_Index, opt);

    % register
    bra.set_bus(a_Bus)
    bra.set_network(obj)
    obj.a_Branch = [obj.a_Branch;{bra}];
    obj.log_edit(obj.str_tag+" <<-Add--- "+bra.str_tag,"Topology");
    
end