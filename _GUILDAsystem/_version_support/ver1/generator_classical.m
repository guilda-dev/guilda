function out = generator_classical(omega,parameter)
    f = parameter.Properties.VariableNames;
    if ismember('T',f) || ~ismember('Tdo',f)
        parameter.Properties.VariableNames(strcmp(f,'T')) = {'Tdo'};
    end
    out = component.generator.classical(parameter);
end