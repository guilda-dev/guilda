function update_scene(obj, k) %#ok<INUSD>
% Show the title of the data: the diagram has one sample and nothing moves.
    arguments (Input)
        obj
        k (1,1) double  % Index of the sample (always 1).
    end
    title(obj.ax(1), obj.sct_data.s_title, "Interpreter", "none", "FontSize", 10, "FontWeight", "normal");
end
