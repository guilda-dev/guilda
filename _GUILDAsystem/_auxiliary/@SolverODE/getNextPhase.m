function [x0, M0] = getNextPhase(ctx, x0, M0, RM, EM)
% Initial value and mass matrix of the next phase from the end of the current one.
%
% A bus faulted in the phase just solved restarts from its equilibrium voltage and current
% (the faults are those of ctx). A tripped unit stays tripped to the end of the run, so its
% entries (zero after the expansion) are left out of every later phase.
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

    for i = 1:ctx.n_bus
        if ctx.lv_fault(i)
            iv = [ctx.iv_V(2*i-1 + (0:1)'); ctx.iv_I(2*i-1 + (0:1)')];
            x0(iv) = ctx.rv_z0(iv);
        end
    end
end
