classdef GUILDA_pref < handle
    properties(Access=protected)
        uifig
        uiText (:,1) cell
        uiEdit (:,1) cell
        uiApply
    end
    properties
        env (1,1) struct = config.systemFunc.get();
        editFlag (1,1) logical = false;
    end

    methods
        function obj = GUILDA_pref()
            obj.uifig  = uifigure('Name','Preference',...
                              'Position',[500,500,360,500],...
                              'CloseRequestFcn',@(src,event) obj.close);
            
            fdname = fieldnames(obj.env);
            obj.build_component(fdname{1});
        end

        function build_component(obj,field)
            data = obj.env.(field);
            str_fields = fieldnames(data);
            num_fields = numel(str_fields);

            obj.uifig.Position(4) = 90 + 30*(num_fields+2) + 60;

            uigrid = uigridlayout(obj.uifig,[2+num_fields, 5],"BackgroundColor",[0.1,0.1,0.1]);

            uitab_field = uidropdown(uigrid, ...
                              'Items',fieldnames(obj.env),...
                              'Value',field,...
                              'FontSize',20,...
                              'FontColor',[1,1,1],...
                              'BackgroundColor',[0,0,0],...
                              "ValueChangedFcn", @(src,event) obj.build_component(src.Value) );
            uibtn_apply = uibutton(uigrid, ...
                              'Text'    ,'Apply',...
                              'FontSize',15,...
                              'FontColor',[1,1,1],...
                              'BackgroundColor',[0,0,0],...
                              "ButtonPushedFcn", @(src,event) obj.set_env );
            uibtn_end  = uibutton(uigrid, ...
                              'Text'    ,'Complete',...
                              'FontSize',15,...
                              'FontColor',[1,1,1],...
                              'BackgroundColor',[0,0,0],...
                              "ButtonPushedFcn", @(src,event) obj.close );

            
            %%%% UI LAYOUT
            uigrid.RowHeight   = [{'3x'}, repmat({'2x'},1,num_fields+2),{'2x'}];
            uigrid.ColumnWidth = {2,'6x','1x','5x',2};
            uitab_field.Layout.Row    = 1;
            uitab_field.Layout.Column = [2,4];
            uibtn_apply.Layout.Row    = 4+num_fields;  
            uibtn_apply.Layout.Column = 2;
            uibtn_end.Layout.Row      = 4+num_fields;  
            uibtn_end.Layout.Column   = [3,4];

            obj.uiApply = uibtn_apply;

            for i = 1:num_fields
                ith_field = str_fields{i};
                ith_data  = data.(ith_field);

                % num_char = numel(char(ith_field));
                % txt = [repmat(' ',1,25-num_char),char(ith_field),'  : '];
                ul = uilabel(uigrid,'Text',ith_field,'FontSize',15,'FontColor',[1,1,1]);
                ul.Layout.Row    = i+2;
                ul.Layout.Column = 2;

                switch ith_data.Type
                    case "double"
                        ue = uitextarea(uigrid, "Value",string(ith_data.Value), ...
                                                "FontColor",[1,1,1], ...
                                                "ValueChangedFcn",@(src,event) obj.fdouble(src,field,ith_field));
                        ue.Layout.Column = [3,4];
                    case "logical"
                        ue = uicheckbox(uigrid, "Text","", ...
                                                "Value",ith_data.Value, ...
                                                "FontColor",[1,1,1], ...
                                                "ValueChangedFcn",@(src,event) obj.flogical(src,field,ith_field));
                        ue.Layout.Column = 3;
                    case "select"
                        list  = ith_data.options;
                        % index = find(list==ith_data.Value);
                        ue = uidropdown(uigrid, "BackgroundColor",[0.2,0.2,0.2], ...
                                                "Items",list, ...
                                                "Value",ith_data.Value, ...
                                                "FontColor",[1,1,1], ...
                                                "ValueChangedFcn",@(src,event) obj.fselect(src,field,ith_field));
                        ue.Layout.Column = [3,4];
                end
                ue.Layout.Row = i+2;
            end
            
        end

        function close(obj)
            if obj.editFlag
                selection = uiconfirm(obj.uifig,...
                    "Apply changed settings?", ...
                    "Confirm", ...
                    "Options",["Apply","Close","Cancel"], ...
                    "DefaultOption",1,"CancelOption",3);
                switch selection
                    case "Apply" ; obj.set_env;
                    case "Close"  
                    case "Cancel"; return
                end
            end
            delete(obj.uifig);
        end

        function set.editFlag(obj,val)
            obj.editFlag = val;
            if obj.editFlag
                obj.uiApply.BackgroundColor = [0,0.3,0.3];%#ok
            else
                obj.uiApply.BackgroundColor = [0,0,0];%#ok
            end
        end
    end

    methods(Access=protected)
        function fdouble(obj,src,field,ith_field)
            num = double(src.Value);
            if isnumeric(num)
                obj.env.(field).(ith_field).Value = num;
                obj.editFlag = true;
            else
                src.Value = string(obj.env.(field).(ith_field).Value);
            end
        end
        function flogical(obj,src,field,ith_field)
            obj.env.(field).(ith_field).Value = src.Value;
            obj.editFlag = true;
        end
        function fselect(obj,src,field,ith_field)
            % val = src.String(src.Value);
            obj.env.(field).(ith_field).Value = src.Value;
            obj.editFlag = true;
        end
        function set_env(obj)
            config.systemFunc.set(obj.env);
            obj.editFlag = false;
        end
    end
end