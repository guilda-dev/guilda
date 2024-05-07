function defineClass

    f = uifigure('Position',[500,400,350,190]);

    
    
    text{1} = uitext(f, [9 145 100 20], '  　クラス名：');
    %text_name.String = 'class name：';
    
    text{2} = uitext(f, [9 120 100 20], '  　　　種類：');
    %text_name.String = 'class name：';

    text{3} = uitext(f, [9  95 100 20], '  モデル説明：');
    %text_name.String = 'class name：';

    edit_name = uicontrol(f,'Style','edit');
    edit_name.Position = [110 145 150 20];
    edit_name.HorizontalAlignment ="left";

    pop = uicontrol(f,'Style','popupmenu');
    pop.Position = [110 120 150 20];
    pop.String = {'component','controller','branch'};

    edit_discription = uicontrol(f,'Style','edit','Max',3);
    edit_discription.Position = [110 55 200 60];
    edit_discription.HorizontalAlignment ="left";
    edit_discription.String = '<message>';
    

    push = uicontrol(f,'Style','pushbutton');
    push.Position = [220 10 100 40];
    push.String = '作成';
    push.FontWeight = 'bold';
    push.FontSize = 13;
    
    
    pop_lang = uicontrol(f,'Style','popupmenu');
    pop_lang.Position = [20 10 60 20];
    pop_lang.String = {'JPN','ENG'};
    pop_lang.FontSize = 8;
    pop_lang.FontWeight = 'bold';
    
    
    push.Callback = @(var1,var2) generate(var1,var2,edit_name,edit_discription,pop,pop_lang);
    pop_lang.Callback = @(var1,var2) set_lang(var1,var2,text,push);
end

function set_lang(var,~,text,push) 
    switch var.String{var.Value}
        case 'JPN'
          text{1}.String = '  　クラス名：'; 
          text{2}.String = '  　　　種類：';
          text{3}.String = '  モデル説明：';
          push.String    = '作成';
        case 'ENG'
          text{1}.String = ' class name :'; 
          text{2}.String = ' model type :';
          text{3}.String = 'discription :';
          push.String    = 'Generate';
    end
end

function generate(~,~,edit_name,edit_discription,pop,lang)
    
    new_name    = edit_name.String;
    discription = edit_discription.String;
    if size(discription,1) ~= 1
        n = size(discription,1);
        temp = char(kron(ones(n-1,1),[newline,'%          ']));
        discription_end = discription(end,:);
        discription = [discription(1:end-1,:),temp].';
        discription = [discription(:)',discription_end];
    end


    filename_ = [uigetdir,filesep,new_name];
    clsname   = new_name;
    filename  = [filename_,'.m'];
    idx = 1;
    while isfile(filename)
        idx = idx +1;
        filename = [filename_,'_',num2str(idx),'.m'];
        clsname  = [new_name,'_',num2str(idx)];
    end

    language = lang.String{lang.Value};
    text_data = fileread([fullfile(tools.pwd,'_GUILDAsystem',['@',pop.String{pop.Value}],'template',language),'.txt']);
    text_data = strrep(text_data,'___NAME___',clsname);
    text_data = strrep(text_data,'___DISCRIPTION___',discription);

    writelines(text_data,filename)
    open(filename)
end

function [filename,idx] = rename_file(filename)
   idx_underbar = find(filename=='_',1,"last");
   idx = str2double(filename(idx_underbar+1:end-2));
   if isfile(filename)
       filename = [filename(1:idx_underbar),num2str(idx+1),'.m'];
       [filename,idx] = rename_file(filename);
   end
end

function out = uitext(f, position, text)
    out = uicontrol(f, 'Style', 'text');
    out.Position    = position;
    out.String      = text;
    out.FontWeight  = 'bold';
    out.FontSize    = 11;

end
