tic
h = mysql( 'open', 'localhost', 'traders', 'qazxc123' );
[ id, field ] = mysql('select i_id, s_field from db.fields ');
mysql('close');
toc
for i =1:size(field,1)
    fields.(cell2mat(field(i))) = id(i);
end

fields