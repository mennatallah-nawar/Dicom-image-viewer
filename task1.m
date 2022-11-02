%%%%Put the file in the same folder with Head dataset%%%%
% Build full file name from parts by (fullfile) , pwd is command to identify current folder.
% dicomlist: List Head folder contents (list of dicom images name)
dicomlist = dir(fullfile(pwd,'Head','*.dcm'));
volume = [];
for i = 1 : numel(dicomlist) % from 1 to lengh of list
    %loop to read dicom images from dicom list  
    I = dicomread(fullfile(pwd,'Head',dicomlist(i).name));
    % Build 3d volume matrix by concatenating axial plans with each other
    volume = cat(3, volume, I);
end

volumeViewer(volume)

for i = 1 : size(volume,3)
    % xy slice :
    Axial = volume(:, :, i); %Move in the Z direction and show all values of xy 
    imshow(Axial,[]) %square brackets to normalize the values of pixels between 0 - 255
end

for i = 1 : size(volume,1)
    % xz slice:
    % permute function to rearrange the order of matrix dimension "to move all values to XY plane" so we can display it
    Coronal = imrotate((permute(volume(i,:,:),[2 3 1])),90); %Move in the Y direction
    imshow(Coronal,[])
end

for i = 1 : size(volume,2)
    % yz slice:
    Sagittal = imrotate((permute(volume(:,i,:),[1 3 2])),90); %Move in the X direction
    imshow(Sagittal,[])
end