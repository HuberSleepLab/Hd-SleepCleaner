function [visnum, vistrack] = read_json_fromSH(fname)
    % A function to read the scoring file (.json format) from Scoring Hero.

    fid = fopen(fname); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    scoring_data = jsondecode(str);

    visnum      = [scoring_data{1}.digit];
    vistrack    = [scoring_data{1}.clean];
end