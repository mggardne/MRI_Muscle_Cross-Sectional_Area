%#######################################################################
%
%               * MUSCle THRESHold Reliability Program *
%
%          M-File which reads a MRI thigh image file and finds the
%     cross-sectional areas for the extensor and flexor muscles,
%     subcutaneous fat and noncontractile elements within the left and
%     right thighs.
%
%          The M-file reads a T1 FFE image file, crops the image, and 
%     thresholds the image.  The user then selects subcutaneous fat,
%     femur and muscle in the left and right thighs.  The program
%     finds all connected muscle and subcutaneous fat tissues.  The
%     femur is filled and used to exclude the femur and marrow from the
%     noncontractile elements within the muscles.  The program prompts
%     the user to create a polygon region of interest around the flexor
%     muscles.  This is used to divide the muscles into extensor and
%     flexor muscles.  The cross-sectional areas for the muscles,
%     subcutaneous fat and noncontractile elements are displayed in the
%     command window and written to a MS-Excel spreadsheet.  Plots are
%     created of the raw image, threshold histogram, muscles,
%     subcutaneous fat and noncontractile elements.
%
%     NOTES:  1.  This program is for the MRI reliability study.  The
%             Matlab program must start in the MRI_Reliability_Study
%             directory.  The directory structure must include
%             subdirectories for each subject and each subject directory
%             must include subdirectories for each visit.  The directory
%             structure is used to identify the MRI images.
%
%             2.  DICOM images are not scaled.  Only raw pixel values
%             are used to segment the muscle tissue.  Designed for
%             Philips 3T T1 FFE MRI images.  The background is set to
%             zero by Philips.
%
%             3.  Program assumes images are gray scale images.
%
%             4.  Otsu's method is used to pick the two thresholds.
%             The program colors pixels below the lower threshold
%             (bone) red and pixels above the upper threshold (fat)
%             green.  The thresholds are shown in a plot of the signal
%             intensity histogram.
%
%             5.  See Polygon_ROI_Guide.pdf for tips on creating the
%             polygon ROI.  See musc_threshr.pdf for a guide to using
%             this program.
%
%             6.  Results are written to the MS-Excel spreadsheet,
%             mthreshr.xlsx in the MRI_Reliability_Study\MuscleCSA\
%             directory.  If the file does not exist, this program
%             creates the file. If the file exists, the results are
%             appended in a row at the bottom of the file.  The output
%             MS-Excel spreadsheet, mthreshr.xlsx, can NOT be open in
%             another program (e.g. MS-Excel, text editor, etc.) while
%             using this program.
%
%             7.  Running the program for the same image will result in
%             duplicate data in the spreadsheet.  The spreadsheet
%             should be checked for duplicate data before statistical
%             analyzes.
%
%             8.  Plots are written to a Postscript file
%             mthreshr_??_v?.ps, where ?? is the subject number and ?
%             is the visit number (1 or 2) into the
%             MRI_Reliability_Study\MuscleCSA\ directory.
%
%             9.  M-file function roi_mov.m must be in the current path
%             or directory.  Both musc_threshr.m and roi.mov.m should
%             be in the MRI_Reliability_Study directory.
%
%             10.  The ROI polygon function requires newer versions of
%             Matlab (2020 and later).
%
%     15-Oct-2021 * Mack Gardner-Morse
%

%#######################################################################
%
% Clear Workspace
%
clc;
clear;
close all;
fclose all;
%
% Check Current Working Directory and Get Results Directory
%
cwd = pwd;
%
if ~contains(cwd,'MRI_Reliability_study','IgnoreCase',true)
  error([' *** Error in musc_threshr:  Current working directory ', ...
        'is not MRI_Reliability_Study\!']);
end
%
rnam = 'MuscleCSA';     % Results directory
%
if ~exist(rnam,'dir')   % Create results directory if it does not exist
  mkdir(rnam);
end
%
% Output MS_Excel Spreadsheet File Name, Sheet Name and Headers/Units
%
xlsnam = fullfile(rnam,'mthreshr.xlsx');    % Put in results directory
shtnam = 'ReliabilityStudy';
hdr = {'Subj ID','Subj #','Visit','MRI Date','Analysis Date', ...
       'L Mus CSA Ext','R Mus CSA Ext','L Mus CSA Flex', ...
       'R Mus CSA Flex','L Mus CSA total','R Mus CSA total', ...
       'L SubFat CSA','R SubFat CSA','L Non Con CSA', ...
       'R Non Con CSA'};     % Column headers
ulbls = [{'','','','',''} cellstr(repmat('(cm^2)',10,1))'];     % Units
%
% Postscript Output File for Plots
%
pfile = 'mthreshr_';     % Postscript output file
%
% Get T1 FFE Image File Name
%
[fnam,pnam] = uigetfile({'*.*',  'All files (*.*)'; ...
                         '*.tif*;*.png*;*.dcm*;*.jpe*;*.jpg*', ...
            'Image files (*.tif*, *.png*, *.dcm*, *.jpe*, *.jpg*)'; ...
            '*.dcm', 'DICOM image files (*.dcm)'}, ...
            'Please Select Image File', ...
            'MultiSelect', 'off');
%
ffnam = fullfile(pnam,fnam);
%
% Get Visit and Subject Numbers from the Path
%
idv = strfind(lower(pnam),'visit');
vtxt = pnam(idv+5);
vn = eval(vtxt);
%
stxtfull = pnam(idv-6:idv-2);
stxt = stxtfull(1:2);
sn = eval(stxt);
%
ttxt = ['Subject ' stxt ' - Visit ' vtxt];  % Image ID
%
pfile = [pfile stxt '_v' vtxt '.ps'];  % Postscript output file
% ppfile = fullfile(pnam(1:idv+5),pfile);     % Put in visit directory
ppfile = fullfile(rnam,pfile);         % Put in results directory
%
% Read T1 FFE Image from File and Get Range
% 
id = isdicom(ffnam);
if id                   % DICOM image format
  info = dicominfo(ffnam);
  img = dicomread(info);
else                    % Other image formats
%    img = imread(ffnam);
  error(' *** Error in musc_threshr:  File is not a DICOM file!');
end
%
im_sz = size(img);
if length(im_sz)>2
  img = img(:,:,1);     % Assume all channels are equal (gray scale)
end
%
rmin = min(img(:));
rmax = max(img(:));
%
% Setup T1 FFE Figure Window
%
hf1 = figure;
orient landscape;
set(hf1,'WindowState','maximized');
pause(0.1);
drawnow;
%
% Set Up Color Map
%
cmap = gray(128);
cmap(1,:) = [1 0 0];                   % Red for lower threshold
cmap(128,:) = [0 0.7 0];               % Green for upper threshold
%
% Display T1 FFE Image
%
imagesc(img,[rmin rmax]);
colormap gray;
axis image;
axis off;
title({ttxt; 'Original T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage',ppfile);
%
% Crop Background From Image
%
[i,j] = find(img>rmin+1);              % Background
idi = min(i):max(i);
idj = min(j):max(j);
%
imgc = img(idi,idj);    % Cropped image
%
% Plot Cropped Image
%
hf2 = figure;
orient landscape;
set(hf2,'WindowState','maximized');
pause(0.1);
drawnow;
%
imagesc(imgc,[rmin rmax]);
colormap gray;
axis image;
axis off;
title({ttxt; 'Cropped T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
% Get Thresholds and Plot Image Histogram
%
lvls = multithresh(imgc,2);            % Otsu's method
%
hf3 = figure;
orient landscape;
set(hf3,'WindowState','maximized');
pause(0.1);
drawnow;
%
histogram(imgc,'FaceAlpha',1,'FaceColor',[0 0 0.8]);
hold on;
axlim = axis;
plot(repmat(lvls(1),2,1),axlim(3:4)','r-','LineWidth',1.0);
plot(repmat(lvls(2),2,1),axlim(3:4)','g-','Color',[0 0.7 0], ...
     'LineWidth',1.0);
%
yt = get(gca,'YTick');
yt = yt(end-1);
text(double(lvls(1))+2,yt,int2str(lvls(1)),'FontSize',12,'Color','r');
text(double(lvls(2))+2,yt,int2str(lvls(2)),'FontSize',12, ...
     'Color',[0 0.7 0]);
%
xlabel('Signal Intensity','FontSize',12,'FontWeight','bold');
ylabel('Frequency','FontSize',12,'FontWeight','bold');
title({ttxt; 'T1 FFE Image Histogram'},'FontSize',16, ...
      'FontWeight','bold');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
% Apply Thresholds and Plot
%
imgt = imgc;            % Image with thresholding
%
imgt(imgt<lvls(1)) = rmin;
imgt(imgt>lvls(2)) = rmax;
%
hf4 = figure;
orient landscape;
set(hf4,'WindowState','maximized');
pause(0.1);
drawnow;
%
imagesc(imgt,[rmin rmax]);
colormap(cmap);
axis image;
axis off;
title({ttxt; 'T1 FFE Image with Thresholds'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
% Get Left Thigh Subcutaneous Fat
%
uiwait(msgbox(['Pick a point within the left thigh subcutaneous ', ...
       'fat.'],'Input','modal'));
[xl,yl] = ginput(1);
xl = round(xl);
yl = round(yl);
%
bwl = grayconnected(imgt,yl,xl,1);     % Get subcutaneous fat
imgl = imgc;
imgl(~bwl) = 0;
%
[i,j] = find(imgl>rmin+1);             % Crop background
idil = min(i):max(i);
idjl = min(j):max(j);
imgl = imgl(idil,idjl); % Cropped image
%
rminl = min(imgl(:));
rmaxl = max(imgl(:));
%
% Get Left Thigh (Leg) Femur
%
uiwait(msgbox('Pick a point within the left thigh femur.', ...
       'Input','modal'));
[xl,yl] = ginput(1);
xl = round(xl);
yl = round(yl);
%
bwfl = grayconnected(imgt,yl,xl,1);    % Get femur
bwfl = imfill(bwfl,'holes');           % Femur and marrow
%
% Get Left Thigh (Leg) Muscle
%
uiwait(msgbox('Pick a point within the left muscle.','Input','modal'));
[xl,yl] = ginput(1);
xl = round(xl);
yl = round(yl);
%
imgbwl = imgt;
imgbwl(imgbwl==rmax) = 0;
imgbwl(imgbwl>=lvls(1)&imgbwl<=lvls(2)) = rmax;
%
bwml = grayconnected(imgbwl,yl,xl,1);  % Get connected muscle
imgml = imgt;
imgml(~bwml) = 0;
imgml = imgml(idil,idjl);              % Cropped image
%
% Get Right Thigh Subcutaneous Fat
%
uiwait(msgbox(['Pick a point within the right thigh subcutaneous ', ...
       'fat.'],'Input','modal'));
[xr,yr] = ginput(1);
xr = round(xr);
yr = round(yr);
%
bwr = grayconnected(imgt,yr,xr,1);     % Get subcutaneous fat
imgr = imgc;
imgr(~bwr) = 0;
%
[i,j] = find(imgr>rmin+1);             % Crop background
idir = min(i):max(i);
idjr = min(j):max(j);
imgr = imgr(idir,idjr); % Cropped image
%
rminr = min(imgr(:));
rmaxr = max(imgr(:));
%
% Get Right Thigh (Leg) Femur
%
uiwait(msgbox('Pick a point within the right thigh femur.', ...
       'Input','modal'));
[xr,yr] = ginput(1);
xr = round(xr);
yr = round(yr);
%
bwfr = grayconnected(imgt,yr,xr,1);    % Get femur
bwfr = imfill(bwfr,'holes');           % Femur and marrow
%
% Get Right Thigh (Leg) Muscle
%
uiwait(msgbox('Pick a point within the right muscle.','Input','modal'));
[xr,yr] = ginput(1);
xr = round(xr);
yr = round(yr);
%
imgbwr = imgt;
imgbwr(imgbwr==rmax) = 0;
imgbwr(imgbwr>=lvls(1)&imgbwr<=lvls(2)) = rmax;
%
bwmr = grayconnected(imgbwr,yr,xr,1);  % Get connected muscle
imgmr = imgt;
imgmr(~bwmr) = 0;
imgmr = imgmr(idir,idjr);              % Cropped image
%
% Set Up Call Backs
%
cb1 = ['chk = get(h1,''Checked''); if strcmp(chk,''off''); ', ...
       'set(hw,''Visible'',''on''); set(h1,''Checked'',''on''); ', ...
       'set(he,''Visible'',''off''); set(h2,''Checked'',''off''); ', ...
       'set(hf,''Visible'',''off''); set(h3,''Checked'',''off''); ', ...
       'end'];
%
cb2 = ['chk = get(h2,''Checked''); if strcmp(chk,''off''); ', ...
       'set(he,''Visible'',''on''); set(h2,''Checked'',''on''); ', ...
       'set(hw,''Visible'',''off''); set(h1,''Checked'',''off''); ', ...
       'set(hf,''Visible'',''off''); set(h3,''Checked'',''off''); ', ...
       'end'];
%
cb3 = ['chk = get(h3,''Checked''); if strcmp(chk,''off''); ', ...
       'set(hf,''Visible'',''on''); set(h3,''Checked'',''on''); ', ...
       'set(hw,''Visible'',''off''); set(h1,''Checked'',''off''); ', ...
       'set(he,''Visible'',''off''); set(h2,''Checked'',''off''); ', ...
       'end'];
%
cb4 = ['chk = get(h4,''Checked''); if strcmp(chk,''off''); ', ...
       'set(hm,''Visible'',''on''); set(h4,''Checked'',''on''); ', ...
       'else; set(hm,''Visible'',''off''); set(h4,''Checked'',' ...
       '''off''); end'];
%
% Get ROI for Left Flexor Muscles
%
imgfl = imgc(idil,idjl);
hf5 = figure;
orient landscape;
set(hf5,'WindowState','maximized');
pause(0.1);
drawnow;
%
imagesc(imgfl);
colormap gray;
axis image;
ha5 = gca;
axis off;
title({ttxt; 'Left Thigh Muscle T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
%
uiwait(msgbox({'Please digitize the left flexor muscle.'; ' '; ...
       'Press <Enter> when finished.'},'Input','modal'));
%
hlroi = images.roi.Polygon(ha5,'LineWidth',1);
addlistener(hlroi,'MovingROI',@roi_mov);
hlroi.draw;
%
kchk = true;
%
while kchk
%
     hlroi.wait;
     lfm = hlroi.createMask;           % Left extensor mask
     pts = hlroi.Position;
     pts = [pts; pts(1,:)];
%
% Get Extensors and Flexors
%
     imgmle = imgml;
     imgmle(lfm) = 0;
     imgmlf = imgml;
     imgmlf(~lfm) = 0;
%
% Set Up Figure and Figure Menus
%
     hl = figure;
     orient landscape;
     set(hl,'WindowState','maximized');
     pause(0.1);
     drawnow;
%
     hw = imagesc(imgml);
     colormap gray;
     axis image;
     axis off;
     title({ttxt; 'Left Thigh Muscle T1 FFE Image'},'FontSize',16, ...
           'FontWeight','bold','Interpreter','none');
     hold on;
%
     he = imagesc(imgmle);
     set(he,'Visible','off');
     hf = imagesc(imgmlf);
     set(hf,'Visible','off');
     hm = plot(pts(:,1),pts(:,2),'r-','LineWidth',1);
%
     h0 = uimenu(hl ,'Label','Muscles');
     h1 = uimenu(h0,'Label','Whole Muscle','Checked','on', ...
                 'CallBack',cb1);
     h2 = uimenu(h0,'Label','Extensors','Checked','off','CallBack',cb2);
     h3 = uimenu(h0,'Label','Flexors','Checked','off','CallBack',cb3);
     h4 = uimenu(h0,'Label','ROI','Checked','on','CallBack',cb4);
%
     kchk = logical(menu('Extensor/Flexor Muscles OK?','Yes','No')-1);
%
     close(hl);
%
     if kchk
       figure(hf5);
     end
%
end
%
close(hf5);
%
% Get ROI for Right Flexor Muscles
%
imgfr = imgc(idir,idjr);
hf6 = figure;
orient landscape;
set(hf6,'WindowState','maximized');
pause(0.1);
drawnow;
%
imagesc(imgfr);
colormap gray;
axis image;
ha6 = gca;
axis off;
title({ttxt; 'Right Thigh Muscle T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
%
uiwait(msgbox({'Please digitize the right flexor muscle.'; ' '; ...
       'Press <Enter> when finished.'},'Input','modal'));
%
hrroi = images.roi.Polygon(ha6,'LineWidth',1);
addlistener(hrroi,'MovingROI',@roi_mov);
hrroi.draw;
%
kchk = true;
%
while kchk
     hrroi.wait;
     rfm = hrroi.createMask;           % Right extensor mask
     pts = hrroi.Position;
     pts = [pts; pts(1,:)];
%
% Get Extensors and Flexors
%
     imgmre = imgmr;
     imgmre(rfm) = 0;
     imgmrf = imgmr;
     imgmrf(~rfm) = 0;
%
% Set Up Figure and Figure Menus
%
     hr = figure;
     orient landscape;
     set(hr,'WindowState','maximized');
     pause(0.1);
     drawnow;
%
     hw = imagesc(imgmr);
     colormap gray;
     axis image;
     axis off;
     title({ttxt; 'Right Thigh Muscle T1 FFE Image'},'FontSize', ...
            16,'FontWeight','bold','Interpreter','none');
     hold on;
%
     he = imagesc(imgmre);
     set(he,'Visible','off');
     hf = imagesc(imgmrf);
     set(hf,'Visible','off');
     hm = plot(pts(:,1),pts(:,2),'r-','LineWidth',1);
%
     h0 = uimenu(hr,'Label','Muscles');
     h1 = uimenu(h0,'Label','Whole Muscle','Checked','on', ...
                 'CallBack',cb1);
     h2 = uimenu(h0,'Label','Extensors','Checked','off','CallBack',cb2);
     h3 = uimenu(h0,'Label','Flexors','Checked','off','CallBack',cb3);
     h4 = uimenu(h0,'Label','ROI','Checked','on','CallBack',cb4);
%
     kchk = logical(menu('Extensor/Flexor Muscles OK?','Yes','No')-1);
%
     close(hr);
%
     if kchk
       figure(hf6);
     end
%
end
%
close(hf6);
%
% Get Left Thigh (Leg) Noncontractile Elements
%
bwlf = imfill(bwml,'holes');           % Get whole muscle area
bwlf = bwlf&~bwfl;      % Remove femur and marrow
imgncl = imgc;
imgncl(~bwlf) = 0;
imgncl = imgncl(idil,idjl);
bwncl = imgncl>lvls(2);
imgncl(~bwncl) = 0;
%
% Get Right Thigh (Leg) Noncontractile Elements
%
bwrf = imfill(bwmr,'holes');           % Get whole muscle area
bwrf = bwrf&~bwfr;      % Remove femur and marrow
imgncr = imgc;
imgncr(~bwrf) = 0;
imgncr = imgncr(idir,idjr);
bwncr = imgncr>lvls(2);
imgncr(~bwncr) = 0;
%
% Get Pixel Size
%
if isfield(info,'PixelSpacing')
  pix2cm = prod(info.PixelSpacing)/100;% Conversion from pixel to cm
  units = 'cm^2';
else
%   pix2cm = 1;
%   units = 'pixel^2';
  error([' *** Error in musc_threshr:  Pixel size not found! ', ...
           ' Cross-sectional areas will be in pixel^2 and not cm^2!']);
end
%
% Calculate and Print Out Muscle Cross-Sectional Areas
%
areaml = sum(bwml(:))*pix2cm;          % Total left muscle
areamr = sum(bwmr(:))*pix2cm;          % Total right muscle
%
bwmle = bwml(idil,idjl);
bwmle(lfm) = 0;
areamle = sum(bwmle(:))*pix2cm;        % Left extensors
bwmlf = bwml(idil,idjl);
bwmlf(~lfm) = 0;
areamlf = sum(bwmlf(:))*pix2cm;        % Left flexors
%
bwmre = bwmr(idir,idjr);
bwmre(rfm) = 0;
areamre = sum(bwmre(:))*pix2cm;        % Right extensors
bwmrf = bwmr(idir,idjr);
bwmrf(~rfm) = 0;
areamrf = sum(bwmrf(:))*pix2cm;        % Right flexors
%
fprintf(1,'\n\nMUSCLE CROSS-SECTIONAL AREAS FOR %s\n',ttxt);
fprintf(1,'Left Thigh Cross-Sectional Area = %.1f %s\n',areaml,units);
fprintf(1,'  Extensors Cross-Sectional Area = %.1f %s\n',areamle, ...
        units);
fprintf(1,'  Flexors Cross-Sectional Area = %.1f %s\n',areamlf,units);
%
fprintf(1,'Right Thigh Cross-Sectional Area = %.1f %s\n',areamr, ...
        units);
fprintf(1,'  Extensors Cross-Sectional Area = %.1f %s\n',areamre, ...
        units);
fprintf(1,'  Flexors Cross-Sectional Area = %.1f %s\n',areamrf,units);
%
% Calculate and Print Out Subcutaneous Fat Cross-Sectional Areas
%
areal = sum(bwl(:))*pix2cm;
arear = sum(bwr(:))*pix2cm;
%
fprintf(1,'\nSUBCUTANEOUS FAT CROSS-SECTIONAL AREAS FOR %s\n',ttxt);
fprintf(1,'Left Thigh Cross-Sectional Area = %.1f %s\n',areal,units);
fprintf(1,'Right Thigh Cross-Sectional Area = %.1f %s\n',arear,units);
%
% Calculate and Print Out Noncontractile Elements Cross-Sectional Areas
%
areancl = sum(bwncl(:))*pix2cm;
areancr = sum(bwncr(:))*pix2cm;
%
fprintf(1,['\nNONCONTRACTILE ELEMENTS CROSS-SECTIONAL AREAS ', ...
           'FOR %s\n'],ttxt);
fprintf(1,'Left Thigh Cross-Sectional Area = %.1f %s\n',areancl,units);
fprintf(1,'Right Thigh Cross-Sectional Area = %.1f %s\n\n\n', ...
        areancr,units);
%
% Check for Output MS-Excel Spreadsheet and Check for Headers/Units
%
if ~exist(xlsnam,'file')
  writecell(hdr,xlsnam,'Sheet',shtnam,'Range','A1');
  writecell(ulbls,xlsnam,'Sheet',shtnam,'Range','A2');
else
  [~,fshtnams] = xlsfinfo(xlsnam);     % Get sheet names in file
  idl = strcmp(shtnam,fshtnams);       % Sheet already exists in file?
  if all(~idl)          % Sheet name not found in file
    writecell(hdr,xlsnam,'Sheet',shtnam,'Range','A1');
    writecell(ulbls,xlsnam,'Sheet',shtnam,'Range','A2');
  else                  % Sheet in the file
    [~,txt] = xlsread(xlsnam,shtnam);
    if size(txt,1)<2    % No headers
      writecell(hdr,xlsnam,'Sheet',shtnam,'Range','A1');
      writecell(ulbls,xlsnam,'Sheet',shtnam,'Range','A2');
    end
  end
end
%
% Get MRI and Today's Dates
%
if isfield(info,'SeriesDate')
  sdate = info.SeriesDate;             % Date of MRI
  sdate = datenum(sdate,'yyyymmdd');
  sdate = datestr(sdate,1);            % Formatted date of MRI
else
  sdate = '';
end
%
adate = date;           % Analysis date (today)
%
% Put Results into a Table and Write to Output Spreadsheet File
%
t = table({stxtfull},sn,vn,{sdate},{adate},areamle,areamre,areamlf, ...
          areamrf,areaml,areamr,areal,arear,areancl,areancr);
writetable(t,xlsnam,'WriteMode','append','Sheet',shtnam, ...
           'WriteVariableNames',false);
%
% Plot Final Left Thigh Muscle and Left Extensors and Flexors
%
hf5 = figure;
orient landscape;
set(hf5,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgml);
colormap gray;
axis image;
axis off;
hold on;
%
text(2,2,sprintf('Cross-sectional area = %.1f %s\n',areaml, ...
     units),'HorizontalAlign','left','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Left Thigh Muscle T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
hf6 = figure;
orient tall;
set(hf6,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
subplot(2,1,1);
imagesc(imgmle);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmle);
xt = dims(2)/2;
yt = 0.85*dims(1);
text(xt,yt,sprintf('Cross-sectional area = %.1f %s\n',areamle, ...
     units),'HorizontalAlign','center','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Left Thigh Muscle T1 FFE Image'; 'Extensor Muscles'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
%
subplot(2,1,2);
imagesc(imgmlf);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmlf);
xt = dims(2)/2;
yt = 0.02*dims(1);
text(xt,yt,sprintf('Cross-sectional area = %.1f %s\n',areamlf, ...
     units),'HorizontalAlign','center','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Left Thigh Muscle T1 FFE Image'; 'Flexor Muscles'}, ...
      'FontSize',16,'FontWeight','bold');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
% Plot Final Right Thigh Muscle and Right Extensors and Flexors
%
hf7 = figure;
orient landscape;
set(hf7,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgmr);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmr,2);
text(dims-1,2,sprintf('Cross-sectional area = %.1f %s\n',areamr, ...
     units),'HorizontalAlign','right','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Right Thigh Muscle T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
hf8 = figure;
orient tall;
set(hf8,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
subplot(2,1,1);
imagesc(imgmre);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmre);
xt = dims(2)/2;
yt = 0.85*dims(1);
text(xt,yt,sprintf('Cross-sectional area = %.1f %s\n',areamre, ...
     units),'HorizontalAlign','center','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Right Thigh Muscle T1 FFE Image'; 'Extensor Muscles'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
%
subplot(2,1,2);
imagesc(imgmrf);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmrf);
xt = dims(2)/2;
yt = 0.02*dims(1);
text(xt,yt,sprintf('Cross-sectional area = %.1f %s\n',areamrf, ...
     units),'HorizontalAlign','center','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Right Thigh Muscle T1 FFE Image'; 'Flexor Muscles'}, ...
      'FontSize',16,'FontWeight','bold');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
% Display Left Thigh Subcutaneous Fat T1 FFE Image
%
hf9 = figure;
orient landscape;
set(hf9,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgl,[rminl rmaxl]);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgl,2);
text(dims-1,2,sprintf('Cross-sectional area = %.1f %s\n',areal, ...
     units),'HorizontalAlign','right','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Left Thigh Subcutaneous Fat T1 FFE Image'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
% Display Right Thigh Subcutaneous Fat T1 FFE Image
%
hf10 = figure;
orient landscape;
set(hf10,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgr,[rminr rmaxr]);
colormap gray;
axis image;
axis off;
hold on;
%
text(2,2,sprintf('Cross-sectional area = %.1f %s\n',arear, ...
     units),'HorizontalAlign','left','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Right Thigh Subcutaneous Fat T1 FFE Image'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
% Display Left Thigh Noncontractile Elements T1 FFE Image
%
hf11 = figure;
orient landscape;
set(hf11,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgncl,[rminl rmaxl]);
colormap gray;
axis image;
axis off;
hold on;
%
text(2,2,sprintf('Cross-sectional area = %.1f %s\n',areancl, ...
     units),'HorizontalAlign','left','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Left Thigh Noncontractile Elements T1 FFE Image'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
% Display Right Thigh Noncontractile Elements T1 FFE Image
%
hf12 = figure;
orient landscape;
set(hf12,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgncr,[rminr rmaxr]);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgncr,2);
text(dims-1,2,sprintf('Cross-sectional area = %.1f %s\n',areancr, ...
     units),'HorizontalAlign','right','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({ttxt; 'Right Thigh Noncontractile Elements T1 FFE Image'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',ppfile);
%
return