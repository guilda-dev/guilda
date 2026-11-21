function clear_selection(obj)
% Empty the selection and remove its overlay.
%
% <@Examples>
% ```matlab
% G.clear_selection();
% ```
    arguments (Input)
        obj
    end
    obj.Selection = strings(1, 0);
    if ~isempty(obj.sct_plt) && all(isgraphics(obj.ax))
        obj.apply_selection();
    end
end
