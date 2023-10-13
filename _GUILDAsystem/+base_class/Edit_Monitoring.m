classdef Edit_Monitoring < handle
    
    properties(Access=protected)
        children = {[]};
        parents  = {[]};
    end
    
    properties(SetAccess=protected)
        is_editted = false;
    end

    methods
        function editted(obj)
            obj.is_editted = true;
            for i = 1:numel(obj.parents)
                parent = obj.parents{i};
                if ismethod(parent,'editted')
                    parent.editted
                end
            end
        end

        function reflected(obj)
            obj.is_editted = false;
            for i = 1:numel(obj.children)
                child = obj.children{i};
                if ismethod(obj.parents,'reflected')
                    child.reflectd;
                end
            end
        end

        function register_parent(obj,p,mode)
            if nargin<2
                return
            end
            if iscell(p)
                p = p(:)';
            else
                p = {p};
            end

            if nargin<3
                mode = 'stack';
            end
            switch mode
                case 'stack'
                    obj.parents = [obj.parents,p];
                case 'overwrite'
                    obj.parents = p;
            end
        end

        function register_child(obj,c,mode)
            if nargin<2
                return
            end
            if iscell(c)
                c = c(:)';
            else
                c = {c};
            end

            if nargin<3
                mode = 'stack';
            end
            switch mode
                case 'stack'
                    obj.children = [obj.children,c];
                case 'overwrite'
                    obj.children = c;
            end
        end
    end
end