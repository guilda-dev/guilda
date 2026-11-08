function bra = add_branch(obj, Key, from_to, opt)
% Add a branch between two buses and return it.
%
% `from_to` names the two end buses by their index in `a_Bus` or by their tags. The
% branch tag is the class header followed by a three-digit number. The addition is
% a "Topology" edit, which makes the power flow stale.
%
% The end buses must exist and differ, and R and X must not both be 0; otherwise the
% network stays unchanged and an error explains the fix.
%
% <@Examples>
% ```matlab
% net.add_branch("pi", [1,2], R=0.01, X=0.085, C=0.088);
% net.add_branch("pi_transformer", ["B004","B007"], X=0.2091, Tap=0.978);
% ```
%
% See also PowerNetwork.remove_branch, PowerNetwork.add_bus, Branch
    arguments (Input)
        obj 
        Key          (1,:) char {tools.mustBeKeyOf(Key, "Branch")}   % Branch model key, e.g. "pi" or "pi_transformer".
        from_to      (1,2) {string,double}   = [1,2]   % End buses [from, to], as indices of a_Bus or as bus tags.
        opt.R        (1,1) double = 0;   % [pu] Series resistance.
        opt.X        (1,1) double = 1;   % [pu] Series reactance.
        opt.C        (1,1) double = 0;   % [pu] Shunt susceptance at each end (half of the line charging).
        opt.Tap      (1,1) double = 1;   % Off-nominal tap ratio (1 for a line).
        opt.Phase    (1,1) double = 0 /180*pi;   % [rad] Phase shift of the transformer.
        opt.Smax     (1,1) double = inf;   % [pu] Limit of the apparent power at both ends (Inf: none).
        opt.Imax     (1,1) double = inf;   % [pu] Limit of the current at both ends (Inf: none).
        opt.Pmax     (1,1) double = inf;   % [pu] Limit of the active power at both ends (Inf: none).
        opt.Qmax     (1,1) double = inf;   % [pu] Limit of the reactive power at both ends (Inf: none).
        opt.Vargmax  (1,1) double = 90/180*pi;   % [rad] Limit of the angle difference between the end buses (Inf: none).
        opt.MidXaxis     (1,:) string = [];   % x coordinates of intermediate points in network diagrams.
        opt.MidYaxis     (1,:) string = [];   % y coordinates of intermediate points in network diagrams.
        opt.Marker       (1,1) string = "-";   % Line style of the branch in network diagrams.
    end
    arguments (Output)
        bra   % Added Branch object.
    end

    % a_Busの番号で指定された場合
    if isnumeric(from_to)
        ir_bus = from_to;
        n_bus  = numel(obj.a_Bus);
        if any(ir_bus < 1 | ir_bus > n_bus | ir_bus ~= fix(ir_bus))
            error(msg("GUILDA:PowerNetwork:BranchBusIndex", mat2str(from_to), char(obj.s_tag), char(string(n_bus))))
        end
    else
        sr_Bus = string(obj.a_Bus)';
        [~,ir_bus] = ismember(from_to, sr_Bus);
        if any(ir_bus == 0)
            error(msg("GUILDA:PowerNetwork:BusNotFound", char(from_to(find(ir_bus == 0, 1))), char(obj.s_tag)))
        end
    end
    a_Bus = obj.a_Bus(ir_bus);

    if ir_bus(1) == ir_bus(2)
        error(msg("GUILDA:PowerNetwork:BranchSelfLoop", char(a_Bus{1}.s_tag)))
    end
    if opt.R == 0 && opt.X == 0
        error(msg("GUILDA:PowerNetwork:BranchZeroImpedance", char(a_Bus{1}.s_tag), char(a_Bus{2}.s_tag)))
    end

    % largest number in use + 1 (after remove_branch, numel+1 may already be taken)
    s_Index = num2str(tools.next_tag_number(string(obj.a_Branch)),"%.3d");

    % Build Instance
    dic    = GUILDA.keymap("Branch");
    mkInst = str2func(dic(string(Key)));
    bra = mkInst(s_Index, opt);

    % register
    bra.a_Bus          = a_Bus;
    bra.a_PowerNetwork = obj;
    obj.a_Branch = [obj.a_Branch;{bra}];
    obj.log_edit(obj.s_tag+" <<-Add--- "+bra.s_tag,"Topology");
    
end