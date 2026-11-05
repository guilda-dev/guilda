function [EM, RM, lv_FBorTC, x0, M0] = initial_condition(net, ph, x0, M0)
% Fault and trip flags of the phase, the reduction of the state vector (without the
% faulted buses and tripped units) and the initial value and mass matrix of the
% phase. x0 and M0 are those at the end of the last phase ([] for the first one).
    arguments (Input)
        net  % Network of the run.
        ph   % Data of the phase (an element of the output of Scenario.compile).
        x0   % Initial value at the end of the last phase, or [] for the first phase.
        M0   % Mass matrix at the end of the last phase, or [] for the first phase.
    end
    arguments (Output)
        EM         % Expansion matrix from the reduced to the full state vector.
        RM         % Reduction matrix from the full to the reduced state vector.
        lv_FBorTC  % True for the entries of the faulted buses and tripped units.
        x0         % Initial value of the reduced state vector.
        M0         % Mass matrix of the reduced state vector.
    end
    a_bus = net.a_Bus;
    BusFault = ph.sv_fault;
    CompTrip = ph.sv_trip;

    rm_M = zeros(0,0);
    rv_V = cell(size(a_bus));
    rv_X = cell(size(a_bus));

    for i=1:numel(a_bus)
        iBus = a_bus{i};
        iBus.l_isFault = ismember(iBus.s_tag, BusFault);

        Ieq = iBus.c_Iequilibrium;
        Veq = iBus.c_Vequilibrium;

        rv_V{i} = [real(Veq); imag(Veq); real(Ieq); imag(Ieq)];

        a_Comp = iBus.a_Component;
        [rv_X{i}, rm_M, CompTrip] = getXM(a_Comp, rv_X{i}, rm_M, CompTrip);
    end

    a_GCs = net.a_GlobalController;
    for k = 1:numel(a_GCs)
        a_GC = a_GCs{k};

        rm_M(a_GC.iv_odeX, a_GC.iv_odeX) = tools.read_mass(a_GC);
        rv_X = [rv_X; {a_GC.rv_Xequilibrium}]; %#ok
    end

    [Btag_all, Ctag_all] = getStateTags(net);
    lv_FBorTC = ismember([Ctag_all; Btag_all], [CompTrip; BusFault]);

    nFBorTC = length(lv_FBorTC);

    EM = speye(nFBorTC);
    RM = speye(nFBorTC);

    EM = EM(:, ~lv_FBorTC);
    RM = RM(~lv_FBorTC, :);

    if isempty(x0)
        x0 = [vertcat(rv_X{:}); vertcat(rv_V{:})];
    else
        % Offsets of the disturbances starting in this phase (see set_offsets)
        for i=1:numel(a_bus)
            a_Comp = a_bus{i}.a_Component;
            for j=1:numel(a_Comp)
                idx = a_Comp{j}.iv_odeX;
                x0(idx) = x0(idx) + a_Comp{j}.rv_Xoffset;
            end
        end
    end
    x0 = RM * x0;

    if isempty(M0)
        nB = numel(a_bus);
        M0 = sparse(blkdiag(rm_M, zeros(nB*4, nB*4)));
    end
    M0 = RM * M0 * RM.';
end
