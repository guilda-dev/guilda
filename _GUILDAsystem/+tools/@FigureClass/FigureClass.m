classdef FigureClass < auxiliary
% Collection of figures created by a script, saved together at the end.
%
% Create an instance at the start of the script, create each figure with its figure
% method, and call save at the end.
%
% <@Examples>
% ```matlab
% F = tools.FigureClass(true, fullfile("figure", mfilename()), "both");
% F.figure("response");
% plot(t, y);
% F.save();      % figure/<script>/1-response.png and fig/1-response.fig
% ```
    properties % Figures
        fig            % Created figures, in order of creation.
        title          % Titles of the figures, used in the file names.
        is_save        % Save the figures when save is called.
        filepath_save  % Folder to save to (e.g. ".../figure/<mfilename()>").
        type_save      % File type: "png", "jpg" or "both" (png and fig).
    end

    methods
        function obj = FigureClass(is_save, filepath_save, type_save)
        % Create an empty collection.
        %
        % Inputs: `is_save` (default false), `filepath_save` (default []) and `type_save`
        % (default "both"); see the properties.
            if nargin < 1, is_save = false; end
            if nargin < 2, filepath_save = []; end
            if nargin < 3, type_save = "both"; end
            obj.fig = [];
            obj.title =[];
            obj.is_save = is_save;
            obj.filepath_save = filepath_save;
            obj.type_save = type_save;
        end

        function figure(obj, title, is_fullscreen)
        % Create a figure and add it to the collection.
        %
        % Inputs: `title` of the figure (default "") and `is_fullscreen` (default false).
            if nargin < 2, title = ""; end
            if nargin < 3, is_fullscreen = false; end
            obj.title = [obj.title, title];
            if is_fullscreen
                obj.fig = [obj.fig, figure("WindowState", "maximized")];
            else
                obj.fig = [obj.fig, figure];
            end
        end

        function save(obj, filepath)
        % Save every figure of the collection when is_save is true.
        %
        % Input `filepath`: folder to save to (default filepath_save).
            if nargin < 2, filepath = obj.filepath_save; end
            if isempty(filepath)
                error("filepath is empty");
            end
            if obj.is_save
                if ~exist(filepath, "dir")
                    mkdir(filepath);
                end
                for i_fig = 1:numel(obj.fig)
                    fig_ = obj.fig(i_fig);
                    filename = fullfile(filepath, num2str(i_fig)+"-"+obj.title(i_fig));
                    if ismember(obj.type_save, ["png", "both"])
                        saveas(fig_, filename + ".png");
                    elseif obj.type_save == "jpg"
                        saveas(fig_, filename + ".jpg");
                    else
                        error("type_save is invalid");
                    end
                    if ismember(obj.type_save, ["png", "both"])
                        filepath_fig = fullfile(filepath, "fig");
                        if ~exist(filepath_fig, "dir")
                            mkdir(filepath_fig);
                        end
                        savefig(fig_, fullfile(filepath_fig, num2str(i_fig) + "-" + obj.title(i_fig) + ".fig"));
                    end
                end
            end
        end
    end
end