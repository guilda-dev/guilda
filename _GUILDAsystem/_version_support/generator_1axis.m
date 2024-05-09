function out = generator_1axis(omega,parameter)
    f = parameter.Properties.VariableNames;
    if ismember('T',f) || ~ismember('Tdo',f)
        parameter.Properties.VariableNames(strcmp(f,'T')) = {'Tdo'};
    end
    out = component.generator.one_axis(parameter);
end