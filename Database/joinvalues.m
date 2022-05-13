function values_str = joinvalues(values)
values_str = '';
if nargin > 0
    values_str = '(';
    fnames = fieldnames(values);
    for f=1:length(fnames)
        str = strtrim(values.(cell2mat(fnames(f))));
        str = ['''' , str, ''''];
        values_str(end+1:end+length(str)) = str;
        values_str(end+1) = ',';
    end
    
    values_str(end) = ')';
end
