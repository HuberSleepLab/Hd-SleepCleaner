

function [visnum, vistrack] = read_json_fromSH (fname)
    %fname = 'I:\Sara\Studies\EPISL\Pilot\SkripteTesten\bi_u_scoringfile.json'; 
    fid = fopen(fname); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    scoring_data = jsondecode(str);

    visnum = [scoring_data{1,1}.digit];
    vistrack = [scoring_data{1,1}.clean];

end