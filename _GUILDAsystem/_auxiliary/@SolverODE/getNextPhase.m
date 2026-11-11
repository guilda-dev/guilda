function [x0, M0] = getNextPhase(ctx, x0, M0, RM, EM)
% Initial value and mass matrix of the next phase from the end of the current one.
%
% A generator tripped in the phase just solved restarts from its equilibrium at the bus
% voltage (and its local controllers from theirs), a faulted bus from its equilibrium
% voltage and current, and a tripped global controller from its equilibrium. The trips and
% faults are those of ctx (the phase just solved).
    arguments (Input)
        ctx                % Context of the run.
        x0   (:,1) double  % Reduced state vector at the end of the phase.
        M0                 % Reduced mass matrix of the phase.
        RM                 %#ok<INUSA> Reduction matrix of the phase.
        EM                 % Expansion matrix of the phase.
    end
    arguments (Output)
        x0  (:,1) double  % Full state vector at the start of the next phase.
        M0                % Full mass matrix at the start of the next phase.
    end
    x0 = EM * x0;
    M0 = EM * M0 * EM.';

    c_comp = ctx.c_comp;
    for j = 1:numel(c_comp)
        b = c_comp{j};
        if ~ctx.lv_compOn(j) && isa(b.comp, 'component.generator.abstract')
            x0(b.iv_x) = b.comp.get_equilibrium([1,1j]*x0(b.iv_V), 0, 0, 0);
            M0(b.iv_x, b.iv_x) = ctx.rm_M(b.iv_x, b.iv_x);

            % Its local controllers restart from their equilibrium too
            for k = reshape(b.iv_lc, 1, [])
                v_LC = ctx.c_lc{k}.iv_x;
                x0(v_LC) = ctx.rv_z0(v_LC);
                M0(v_LC, v_LC) = ctx.rm_M(v_LC, v_LC);
            end
        end
    end

    a_bus = ctx.net.a_Bus;
    for i = 1:numel(a_bus)
        if ctx.lv_fault(i)
            iv = [ctx.iv_V(2*i-1 + (0:1)'); ctx.iv_I(2*i-1 + (0:1)')];
            x0(iv) = ctx.rv_z0(iv);
        end
    end

    % A global controller tripped in the phase just solved restarts from its
    % equilibrium, like a tripped generator (EM left its states and mass at zero)
    for k = 1:numel(ctx.c_gc)
        if ~ctx.lv_gcOn(k)
            idx_GC = ctx.c_gc{k}.iv_x;
            x0(idx_GC) = ctx.rv_z0(idx_GC);
            M0(idx_GC, idx_GC) = ctx.rm_M(idx_GC, idx_GC);
        end
    end
end
