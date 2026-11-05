function verdict = judge(obj, result)
% Judge a simulation result with the Judge function of the scenario.
%
% Returns Judge(result). With the default Judge (Scenario.out_of_step) the verdict is a
% struct with Verdict ("stable", "out-of-step" or "incomplete"), Time, Units,
% MaxAngle, Reference and Threshold. net.simulate does not judge: call this method on
% its result.
%
% <@Examples>
% ```matlab
% result  = net.simulate(sc);
% verdict = sc.judge(result);
% sc.Judge = @(r) Scenario.out_of_step(r, Reference="COI", Threshold=180);
% ```
    arguments (Input)
        obj
        result (1,1) ResultODE % Result of net.simulate.
    end
    arguments (Output)
        verdict % Output of Judge (a struct for Scenario.out_of_step).
    end
    verdict = obj.Judge(result);
end
