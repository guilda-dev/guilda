function applyEdit(obj)
    obj.editFlag = "initialized";
    obj.editLog = [];
    cellfun(@(c) c.applyEdit, obj.children);
end