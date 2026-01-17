function checkParent(obj)
    if isa(BusInstance,'LayerPackage')
        str_par = string(class(obj.parent));
        str_tag = obj.get_tag(true);
        str_info= newline + ...
                  " parent : " + str_par + newline + ...
                  "    Tag : " + str_tag + newline;
        error(config.lang("このクラスは既に別のクラスに登録されています。"+str_info, ...
                          "This class is already registered in another class."+str_info))
    end
end