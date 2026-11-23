function doc(obj)
% Open the class reference page of the model's class.
%
% Opens the GUILDA class reference (English page) of class(obj) in the browser, as
% GUILDA.doc("class", class(obj)). doc with a class name (doc PowerNetwork) is
% MATLAB's doc.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.doc()                          % page of the network class
% net.a_Bus{1}.doc()                 % page of the class of the first bus
% net.a_Bus{1}.a_Component{1}.doc()  % page of the class of its component
% doc(net)                           % same as net.doc()
% ```
    arguments (Input)
        obj (1,1)  % Model whose class page is opened.
    end
    GUILDA.doc("class", class(obj));
end
