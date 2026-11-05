function [x0, M0] = getNextPhase(ctx, x0, M0, RM, EM)
% Initial value and mass matrix of the next phase from the end of the current one.
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
    a_bus  = ctx.net.a_Bus;

    x0 = EM * x0;
    M0 = EM * M0 * EM.';

    for i=1:numel(a_bus)
        a_Comp = a_bus{i}.a_Component;

        b_idx_V = a_bus{i}.iv_odeX;
        b_idx_I = a_bus{i}.iv_odeI;

        for j=1:numel(a_Comp)
            if isa(a_Comp{j}, 'component.generator.abstract') && ~a_Comp{j}.l_isConnect
                c_idx = a_Comp{j}.iv_odeX;
                b_idx = a_bus{i}.iv_odeX;
                x0(c_idx) = a_Comp{j}.get_equilibrium([1,1j]*x0(b_idx), 0, 0, 0);

                % Its local controllers restart from their equilibrium too
                c_LC = controllers_depth_first(a_Comp{j});
                for k = 1:numel(c_LC)
                    v_LC = c_LC{k}.iv_odeX;
                    x0(v_LC) = c_LC{k}.rv_Xequilibrium;
                    M0(v_LC, v_LC) = tools.read_mass(c_LC{k});
                end

                M0(c_idx, c_idx) = tools.read_mass(a_Comp{j});
            end
        end

        if a_bus{i}.l_isFault
            x0([b_idx_V;b_idx_I]) = [real(a_bus{i}.c_Vequilibrium);
                                     imag(a_bus{i}.c_Vequilibrium);
                                     real(a_bus{i}.c_Iequilibrium);
                                     imag(a_bus{i}.c_Iequilibrium)];
        end
    end

    % A global controller tripped in the phase just solved restarts from its
    % equilibrium, like a tripped generator (EM left its states and mass at zero)
    a_GCs = ctx.net.a_GlobalController;
    for k = 1:numel(a_GCs)
        if ~a_GCs{k}.l_isConnect
            idx_GC = a_GCs{k}.iv_odeX;
            x0(idx_GC) = a_GCs{k}.rv_Xequilibrium;
            M0(idx_GC, idx_GC) = tools.read_mass(a_GCs{k});
        end
    end
end
