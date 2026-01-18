function setting()
% Settings (GUI launches)

    fontcolor  = [0,0,0];
    backcolor  = [150,220,255]/256;
    backcolor2 = [100,180,250]/256;
    
    pathlogo   = fullfile(GUILDA.pwd,"@GUILDA","config","GUILDAlogo.png");
    uifig = uifigure('Name','Preference',...
                     'Position',[500,500,850,500],...
                     'CloseRequestFcn',@(src,event) closeUI(src,[]), ...
                     'Color',backcolor);

    env = get_config();
    editFlag = false;

    fdname  = fieldnames(env);
    build_component(uifig,fdname{1});

    
    function build_component(uifig, field)
        data = env.(field);
        str_fields = fieldnames(data);
        num_fields = numel(str_fields);
    
        uifig.Position(4) = 90 + 30*(num_fields+2) + 60;
        uigrid = uigridlayout(uifig,[2+num_fields, 5],"BackgroundColor",backcolor);
        uitab_field = uidropdown(uigrid, ...
                          'Items',fieldnames(env),...
                          'Value',field,...
                          'FontSize',20,...
                          'FontColor',fontcolor,...
                          "FontWeight","bold",...
                          'BackgroundColor',backcolor2,...
                          "ValueChangedFcn", @(src,event) build_component(uifig, src.Value) );
        uibtn_apply = uibutton(uigrid, ...
                          'Text'    ,'Apply',...
                          'FontSize',15,...
                          'FontColor',fontcolor,...
                          "FontWeight","bold",...
                          'BackgroundColor',backcolor,...
                          "ButtonPushedFcn", @(src,event) set_env(src) );
        uibtn_end  = uibutton(uigrid, ...
                          'Text'    ,'Complete',...
                          'FontSize',15,...
                          'FontColor',fontcolor,...
                          "FontWeight","bold",...
                          'BackgroundColor',backcolor,...
                          "ButtonPushedFcn", @(src,event) closeUI(uifig,uibtn_apply) );
        
        uiimg_guilda = uiimage(uigrid,"ImageSource",pathlogo);
        
        %%%% UI LAYOUT
        uigrid.RowHeight          = [{'3x'},{'0.5x'},repmat({'2x'},1,num_fields),{'1x'},{'2x'}];
        uigrid.ColumnWidth        = {2,'5x','13x','1x','1x','4x',2};
        uiimg_guilda.Layout.Row   = 1;
        uiimg_guilda.Layout.Column= 6;
        uitab_field.Layout.Row    = 1;
        uitab_field.Layout.Column = [2,3];
        uibtn_apply.Layout.Row    = 4+num_fields;  
        uibtn_apply.Layout.Column = 2;
        uibtn_end.Layout.Row      = 4+num_fields;  
        uibtn_end.Layout.Column   = 6;

        for i = 1:num_fields
            ith_field = str_fields{i};
            ith_data  = data.(ith_field);

            ul               = uilabel(uigrid,'Text',ith_field,'FontSize',15,'FontColor',fontcolor,"FontWeight","bold","HorizontalAlignment","right");
            ul.Layout.Row    = i+2;
            ul.Layout.Column = 2;

            ul               = uilabel(uigrid,'Text',": "+ith_data.Description,'FontSize',13,'FontColor',fontcolor);
            ul.Layout.Row    = i+2;
            ul.Layout.Column = 3;
            ul               = uilabel(uigrid,'Text'," >> ",'FontSize',15,'FontColor',fontcolor,"FontWeight","bold");
            ul.Layout.Row    = i+2;
            ul.Layout.Column = 4;

            switch ith_data.Type
                case "double"
                    ue = uitextarea(uigrid, "BackgroundColor", [1,1,1],...
                                            "Value",string(ith_data.Value), ...
                                            "FontColor",fontcolor, ...
                                            "FontWeight","bold",...
                                            "ValueChangedFcn",@(src,event) fdouble(src,field,ith_field,uibtn_apply));
                    ue.Layout.Column = [5,6];
                case "logical"
                    ue = uicheckbox(uigrid, "Text","", ...
                                            "Value",ith_data.Value, ...
                                            "FontColor",fontcolor, ...
                                            "FontWeight","bold",...
                                            "ValueChangedFcn",@(src,event) flogical(src,field,ith_field,uibtn_apply));
                    ue.Layout.Column = 5;
                case "select"
                    list  = ith_data.options;
                    ue = uidropdown(uigrid, "BackgroundColor",[1,1,1], ...
                                            "Items",list, ...
                                            "Value",ith_data.Value, ...
                                            "FontColor",fontcolor, ...
                                            "FontWeight","bold",...
                                            "ValueChangedFcn",@(src,event) fselect(src,field,ith_field,uibtn_apply));
                    ue.Layout.Column = [5,6];
            end
            ue.Layout.Row = i+2;
        end
    
    end



    function closeUI(uifig,uiApply)
        if editFlag
            selection = uiconfirm(uifig,...
                "Apply changed settings?", ...
                "Confirm", ...
                "Options",["Apply","Close","Cancel"], ...
                "DefaultOption",1,"CancelOption",3);
            switch selection
                case "Apply" ; set_env(uiApply);
                case "Close"  
                case "Cancel"; return
            end
        end
        delete(uifig);
    end

    function set_editFlag(val,uiApply)
        editFlag = val;
        if editFlag
            uiApply.BackgroundColor = [0,191,218]/256;
        else
            uiApply.BackgroundColor = backcolor;
        end
    end
    
    function fdouble(src,field,ith_field,uiApply)
        num = double(string(src.Value{1}));
        if isnumeric(num)
            env.(field).(ith_field).Value = num;
            set_editFlag(true,uiApply);
        else
            src.Value = string(env.(field).(ith_field).Value);
        end
    end
    function flogical(src,field,ith_field,uiApply)
        env.(field).(ith_field).Value = src.Value;
        set_editFlag(true,uiApply);
    end
    function fselect(src,field,ith_field,uiApply)
        env.(field).(ith_field).Value = src.Value;
        set_editFlag(true,uiApply)
    end
    function set_env(uiApply)
        set_config(env);
        if ~isempty(uiApply)
            set_editFlag(false,uiApply)
        end
    end

end