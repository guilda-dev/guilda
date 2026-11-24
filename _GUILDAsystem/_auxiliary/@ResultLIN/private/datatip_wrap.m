function datatip_wrap(fig, h_owner, fcn_text)
% Add to the data tips of a figure: wrap the UpdateFcn of its data cursor mode.
%
% The diagram and the matrix graphs turn on the data cursor mode of their figure, so a
% click on a graphics object makes a data tip (and calls the UpdateFcn) instead of its
% ButtonDownFcn. The wrapper calls the UpdateFcn set before (the text of the graph, which
% also reports the click) and then fcn_text(event, txt) for the text shown, so that the
% mode figures of ResultLIN pick a mode from a data tip on an eigenvalue. The color value
% of an element of a diagram is written by GraphNetDiagram itself. A figure already wrapped for h_owner (the first in the chain) is not wrapped
% again; a wrapper whose h_owner was deleted passes the text on unchanged.
    arguments (Input)
        fig                      % Figure of the plot.
        h_owner                  % Graphics object of the plot (its panel or axes) that the wrapper belongs to.
        fcn_text function_handle % txt = fcn_text(event, txt_before): the text of the data tip.
    end
    dcm = datacursormode(fig);
    fcn_prev = dcm.UpdateFcn;
    if isa(fcn_prev, "function_handle") && contains(func2str(fcn_prev), "datatip_text(") ...
            && isequal(functions(fcn_prev).workspace{1}.h_owner, h_owner)
        return
    end
    set(dcm, "Enable", "on", "UpdateFcn", @(src, event) datatip_text(src, event, fcn_prev, h_owner, fcn_text));
end


function txt = datatip_text(src, event, fcn_prev, h_owner, fcn_text)
% Text of a data tip: the text of the UpdateFcn before, then fcn_text
    arguments (Input)
        src                      % Data cursor of the figure.
        event                    % Event data of the data tip (Target, Position).
        fcn_prev                 % UpdateFcn set before ([] for none).
        h_owner                  % Graphics object of the plot.
        fcn_text function_handle % Text of the plot.
    end
    arguments (Output)
        txt                      % Text of the data tip.
    end
    if isa(fcn_prev, "function_handle")
        txt = fcn_prev(src, event);
    else
        rv_p = event.Position;
        txt = {sprintf('X: %.4g', rv_p(1)), sprintf('Y: %.4g', rv_p(2))};
    end
    if isgraphics(h_owner)
        txt = fcn_text(event, txt);
    end
end
