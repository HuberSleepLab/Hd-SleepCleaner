function [visnum] = split_sleep_epochs(visnum, scoringlen, epolen)

% This function split sleep scoring epochs in smaller units. It requires
% the latencies of epochs which will be screened, the length of sleep
% scored epochs, and the length of epochs that shall be used during the
% arifact removal routine.

    if scoringlen > epolen                
        if mod(scoringlen, epolen) == 0
            fraction = scoringlen / epolen;
            fprintf('\n Sleep scoring epochs were split in %d!', fraction)

%             % *** Stages of interest
%             % Binary vector of sleep stages of interest
%             sleep01 = zeros(1, max(stages_of_interest));
%             sleep01(stages_of_interest) = 1;
% 
%             % Replicate this vector row-wise
%             sleep01 = repmat(sleep01, fraction, 1);
% 
%             % Split sleep scored epochs in smaller subunits
%             stages_of_interest_split = find(sleep01);

            % *** visnum
            visnum = repmat(visnum, fraction, 1);
            visnum = visnum(:)';
            

        else
            error(' <epolen> must be divisible by <scoringlen>, e.g. 30 / 10, but not 30 / 7.')
        end
    end
end