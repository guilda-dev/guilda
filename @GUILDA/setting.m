function setting(s_category, varargin)
% Change the GUILDA settings: in the settings window, or by command
%
% Without inputs, opens the settings window (GUI). With a category and Name-Value
% arguments, changes those settings without opening the window. Each value is checked
% against the type of the setting ("double", "logical", "string", or "select" with its
% options); an unknown category or name, or an invalid value, stops with an error and
% changes nothing. The change is saved in @GUILDA/user, as with Apply in the window, so it
% stays after MATLAB restarts, and the next GUILDA.config call and analysis use it.
%
% A new version of GUILDA may reset the settings of a category to their defaults (INFO
% at startup): the user settings of a category are kept only while the version of its
% default file stays the same.
%
% <@Examples>
% ```matlab
% GUILDA.setting
% GUILDA.setting("PowerFlowCalculation", Tolerance=1e-10, WhenFailed="ERROR")
% GUILDA.config("PowerFlowCalculation", "Tolerance")
% ```
%
% See also GUILDA.config
    arguments (Input)
        s_category string {mustBeScalarOrEmpty} = string.empty   % Settings category, e.g. "PowerFlowCalculation"; omit to open the window.
    end
    arguments (Input, Repeating)
        varargin   % Name-Value pairs: setting name and new value.
    end

    if ~isempty(s_category)
        set_by_command(s_category, varargin);
        return
    end

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
        sv_fields  = fieldnames(data);
        num_fields = numel(sv_fields);
    
        % Clean up existing UI components before rebuilding
        % delete(uifig.Children);

        uifig.Position(4) = 60 + 20+30*(num_fields)+20+60;
        
        %%%% UI LAYOUT
        uigrid = uigridlayout(uifig,[num_fields+4, 7],"BackgroundColor",backcolor);
        uigrid.RowHeight          = [{'2x'},{'0.5x'},repmat({'1x'},1,num_fields),{'0.5x'},{'2x'}];
        uigrid.ColumnWidth        = {2,'5x','13x','1x','1x','4x',2};

        uitab_field = uidropdown(uigrid, ...
                          'Items',fieldnames(env),...
                          'Value',field,...
                          'FontSize',20,...
                          'FontColor',fontcolor,...
                          "FontWeight","bold",...
                          'BackgroundColor',backcolor2,...
                          "ValueChangedFcn", @(src,event) build_component(uifig, src.Value) );
        uitab_field.Layout.Row    = 1;
        uitab_field.Layout.Column = [2,3];

        uibtn_apply = uibutton(uigrid, ...
                          'Text'    ,'Apply',...
                          'FontSize',15,...
                          'FontColor',fontcolor,...
                          "FontWeight","bold",...
                          'BackgroundColor',backcolor,...
                          "ButtonPushedFcn", @(src,event) set_env(src) );
        uibtn_apply.Layout.Row    = 4+num_fields;  
        uibtn_apply.Layout.Column = 2;

        uibtn_end  = uibutton(uigrid, ...
                          'Text'    ,'Complete',...
                          'FontSize',15,...
                          'FontColor',fontcolor,...
                          "FontWeight","bold",...
                          'BackgroundColor',backcolor,...
                          "ButtonPushedFcn", @(src,event) closeUI(uifig,uibtn_apply) );
        uibtn_end.Layout.Row      = 4+num_fields;  
        uibtn_end.Layout.Column   = 6;
        
        uiimg_guilda = uiimage(uigrid,"ImageSource",pathlogo);
        uiimg_guilda.Layout.Row   = 1;
        uiimg_guilda.Layout.Column= 6;

        

        for i = 1:num_fields
            ith_field = sv_fields{i};
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
                case "string"
                    ue = uieditfield(uigrid, "text", ...
                                            "BackgroundColor",[1,1,1], ...
                                            "Value",char(strjoin(string(ith_data.Value), ", ")), ...
                                            "FontColor",fontcolor, ...
                                            "FontWeight","bold",...
                                            "ValueChangedFcn",@(src,event) fstring(src,field,ith_field,uibtn_apply));
                    ue.Layout.Column = [5,6];
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
    function fstring(src,field,ith_field,uiApply)
        % comma-separated text -> string row (e.g. "Q, V" -> ["Q","V"])
        sv = strtrim(split(string(src.Value), ","))';
        sv = sv(sv ~= "");
        if isempty(sv)
            src.Value = char(strjoin(string(env.(field).(ith_field).Value), ", "));
            return
        end
        env.(field).(ith_field).Value = sv;
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


function set_by_command(s_category, c_nv)
    % Check the Name-Value pairs against the settings of the category, then save them all
    arguments (Input)
        s_category (1,1) string   % Settings category.
        c_nv       cell           % Name-Value pairs.
    end
    env = get_config();
    if ~isfield(env, s_category)
        error(msg("GUILDA:GUILDA:UnknownSettingCategory", s_category, strjoin(string(fieldnames(env)), ", ")))
    end
    sct = env.(s_category);
    if mod(numel(c_nv), 2) ~= 0 || isempty(c_nv)
        error(msg("GUILDA:GUILDA:SettingNameValue", s_category))
    end
    for k = 1:2:numel(c_nv)
        s_name = c_nv{k};
        if ~(ischar(s_name) || isstring(s_name) && isscalar(s_name)) || ~isfield(sct, s_name)
            if ~(ischar(s_name) || isstring(s_name))
                s_name = "(" + class(s_name) + ")";
            end
            error(msg("GUILDA:GUILDA:UnknownSettingName", string(s_name), s_category, ...
                strjoin(string(fieldnames(sct)), ", ")))
        end
        s_name = char(s_name);
        [val, l_ok, s_expect] = check_value(sct.(s_name), c_nv{k+1});
        if ~l_ok
            error(msg("GUILDA:GUILDA:InvalidSettingValue", s_category, s_name, s_expect))
        end
        sct.(s_name).Value = val;
    end
    env.(s_category) = sct;
    set_config(env);
end


function [val, l_ok, s_expect] = check_value(sct_set, val)
    % Check a new value against the Type (and options) of the setting; convert it to the stored class
    arguments (Input)
        sct_set (1,1) struct   % Setting: fields Value, Type, Description (and options).
        val                    % New value.
    end
    arguments (Output)
        val       % Value in the stored class.
        l_ok      % true when the value is valid.
        s_expect  % Description of the accepted values (for the error message).
    end
    switch sct_set.Type
        case "double"
            s_expect = "a real numeric scalar";
            l_ok = (isnumeric(val) || islogical(val)) && isscalar(val) && isreal(val);
            if l_ok, val = double(val); end
        case "logical"
            s_expect = "true or false";
            l_ok = (islogical(val) || isnumeric(val) && ismember(val, [0 1])) && isscalar(val);
            if l_ok, val = logical(val); end
        case "select"
            sv_opt   = string(sct_set.options);
            s_expect = "one of " + strjoin("""" + sv_opt(:)' + """", ", ");
            l_ok = (ischar(val) && (isrow(val) || isempty(val)) || isstring(val) && isscalar(val)) ...
                   && ismember(string(val), sv_opt);
            if l_ok, val = string(val); end
        case "string"
            s_expect = "text (a string array, a character vector or a cell array of character vectors)";
            l_ok = isstring(val) && ~any(ismissing(val)) || ischar(val) && (isrow(val) || isempty(val)) || iscellstr(val);
            if l_ok, val = reshape(string(val), 1, []); end
        otherwise
            s_expect = "a value of type " + sct_set.Type;
            l_ok = false;
    end
end
