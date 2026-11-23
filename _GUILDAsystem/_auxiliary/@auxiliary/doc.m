function doc(obj)
% Open the class reference page of the object's class.
%
% Opens the GUILDA class reference (English page) of class(obj) in the browser, as
% GUILDA.doc("class", class(obj)). doc with a class name (doc ResultPF) is MATLAB's
% doc.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% res = net.calculate_powerflow();
% res.doc()                       % page of ResultPF
% doc(res)                        % same as res.doc()
% sc = net.add_scenario("CASE1");
% sc.doc()                        % page of Scenario
% ```
    arguments (Input)
        obj (1,1)  % Object whose class page is opened.
    end
    GUILDA.doc("class", class(obj));
end
