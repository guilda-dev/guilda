function hv_ax = make_axes(obj, h_parent, n_panel, rv_grid)
% Axes of the graph: n_panel new axes in a tiled layout in a container, or the axes given.
%
% h_parent is
%
% - empty: a new figure;
% - a container (figure, uifigure, uipanel, uitab or uigridlayout): a new tiledlayout of
%   rv_grid(1) rows and rv_grid(2) columns (default n_panel x 1) is made in it, and the
%   n_panel axes fill its tiles row by row (tiles after the last panel stay empty). A
%   uigridlayout does not take a tiledlayout, so a borderless uipanel is put in its next
%   free cell first and the tiledlayout goes in it; to choose the cell, set Layout.Row and
%   Layout.Column of that panel (G.ax(1).Parent.Parent) afterwards. Other contents of the
%   container stay.
% - an axes or uiaxes (single-panel graphs only): the graph draws into it directly. A
%   graph with several panels stops with GUILDA:GraphBase:ParentNeedsContainer.
%
% build calls it with the panel count and the grid of the subclass. A grid with fewer tiles
% than panels is an error (GUILDA:GraphBase:GridSize).
    arguments (Input)
        obj
        h_parent                                                            % Container or axes; [] for a new figure.
        n_panel (1,1) double {mustBeInteger, mustBePositive} = 1            % Number of panels (axes).
        rv_grid (1,2) double {mustBeInteger, mustBePositive} = [n_panel 1]  % Rows and columns of the tiled layout.
    end
    arguments (Output)
        hv_ax (:,1)  % Axes of the panels. <@Type> matlab.graphics.axis.Axes
    end
    if prod(rv_grid) < n_panel
        error(msg("GUILDA:GraphBase:GridSize", class(obj), n_panel, rv_grid(1), rv_grid(2)));
    end
    if isempty(h_parent)
        h_parent = figure("Color", "w");
    end
    if isscalar(h_parent) && isa(h_parent, "matlab.graphics.axis.Axes")
        if n_panel > 1
            error(msg("GUILDA:GraphBase:ParentNeedsContainer", class(obj), n_panel));
        end
        hv_ax = h_parent;
        return
    end
    sv_container = ["matlab.ui.Figure", "matlab.ui.container.Panel", "matlab.ui.container.Tab", ...
                    "matlab.ui.container.GridLayout"];
    if ~(isscalar(h_parent) && isgraphics(h_parent) && any(arrayfun(@(s) isa(h_parent, s), sv_container)))
        error(msg("GUILDA:GraphBase:ParentType", class(obj), class(h_parent)));
    end
    if isa(h_parent, "matlab.ui.container.GridLayout")
        h_parent = uipanel(h_parent, "BorderType", "none");
    end
    tl = tiledlayout(h_parent, rv_grid(1), rv_grid(2), "TileSpacing", "compact", "Padding", "compact");
    hv_ax = gobjects(n_panel, 1);
    for i = 1:n_panel
        hv_ax(i) = nexttile(tl);
    end
end
