% 自作Figureクラス
% 使い方: コード冒頭で本クラスのインスタンスを定義、figure作成時には本クラスのfigureメソッドを使う、コードの最後でsaveメソッドを使う
% is_save: figureを保存するかどうか
% filepath_save: 保存するファイルパス(".../figure/{filename}"を想定, {filename}はmfilename()で取得)
% type_save: 保存するファイルの拡張子(png, fig, jpg, both: png&fig)

classdef FigureClass < handle
    properties
        fig
        title
        is_save
        filepath_save
        type_save
    end

    methods
        function obj = FigureClass(is_save, filepath_save, type_save)
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