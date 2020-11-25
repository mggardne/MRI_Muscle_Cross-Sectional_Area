function roi_mov(src,evt)
%ROI_MOV   Gets data from the ROI listener MovingROI to allow movements of
%          vertices, but block movements of the whole ROI.
%
%          ROI_MOV(SRC,EVT) Collects the previous and current positions
%          of the ROI.  If more than one position is changing, it sets
%          the current position to the previous position.
%
%          NOTES:  1.  See M-file musc_thresh.m for more information.
%
%          24-Nov-2020 * Mack Gardner-Morse
%

%#######################################################################
%
% Get Positions
%
prevpos = evt.PreviousPosition;
currpos = evt.CurrentPosition;
%
% More Than One Position Changing?
%
delpos = currpos-prevpos;
dd = sum(abs(delpos)>0.01);
if any(dd>1)
  src.Position = prevpos;
end
%
return