classdef Modalities_FinalProject < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        EditField            matlab.ui.control.NumericEditField
        MeasurmentsDropDown  matlab.ui.control.DropDown
        ObliqueLabel         matlab.ui.control.Label
        CoronalLabel         matlab.ui.control.Label
        SagittalLabel        matlab.ui.control.Label
        AxialLabel           matlab.ui.control.Label
        BrowseButton         matlab.ui.control.Button
        UIAxes3              matlab.ui.control.UIAxes
        UIAxes4              matlab.ui.control.UIAxes
        UIAxes2              matlab.ui.control.UIAxes
        UIAxes1              matlab.ui.control.UIAxes
    end


    properties (Access = public)
        BrowseFlag
        Axial % Description
        Coronal
        Sagittal
        volume
        Axial_Horizontal
        Axial_Vertical
        Axial_Diagonal
        Sagittal_Horizontal
        Sagittal_Vertical
        Coronal_Horizontal
        Coronal_Vertical
        obliq

        %%%variables to determine position of lines%%%
        A_x
        A_y
        AD_x1
        AD_y1
        AD_x2
        AD_y2

        C_x
        C_y

        S_x
        S_y
        
        ROI
    end
    methods (Access = public)


        %%%%%%%%%%%%%%%%%%%Draw and Detect moving in axial lines and show their effects on other planes%%%%%%%%%%%%%%%%%%%

        function AxialLines(app,x,y,Dx1 ,Dy1,Dx2,Dy2)
            % draw lines on axial plane
            app.Axial_Horizontal = drawline("Parent",app.UIAxes1,'Position',[-1000 y;1000 y],"Color","red","InteractionsAllowed",'translate');
            app.Axial_Vertical = drawline("Parent",app.UIAxes1,'Position',[x -1000;x 1000],"Color","blue","InteractionsAllowed",'translate');
            app.Axial_Diagonal = drawline("Parent",app.UIAxes1,'Position',[Dx1 Dy1;Dx2 Dy2],"Color","yellow");
            %app.Axial_Diagonal = drawline("Parent",app.UIAxes1,'Position',[0 0;size(app.Axial,2) size(app.Axial,1)],"Color","yellow");
            addlistener(app.Axial_Horizontal,'ROIMoved',@cronal_from_axial);
            addlistener(app.Axial_Vertical,'ROIMoved',@saggital_from_axial);
            addlistener(app.Axial_Diagonal,'ROIMoved',@obliq_from_axial);


            function obliq_from_axial(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;

                        %line start point
                        app.AD_x1 = round(pos (1,1));
                        app.AD_y1 = round(pos (1,2));
                        %line end point
                        app.AD_x2 = round(pos (2,1));
                        app.AD_y2 = round(pos (2,2));

                        %get three points on plane with random z_values
                        point1 = [app.AD_x1 app.AD_y1 randi([1 size(app.volume,3)])];
                        point2 = [app.AD_x2 app.AD_y2 randi([1 size(app.volume,3)])];
                        point3 = [app.AD_x2 app.AD_y2 randi([1 size(app.volume,3)])];

                        %get two lines on the plane between previus points
                        line1 = point2-point1;
                        line2 = point3-point2;

                        %Croos product between line1 & 2 to get normal
                        normal = cross (line1,line2); % right direction when (x->0 or negative) and (y->positive)

                        if (normal(1)>0)
                            normal(1) = normal(1)*-1;
                        end

                        if (normal(2)<0)
                            normal(2) = normal(2)*-1;
                        end

                        %calculate angle between diagonal and x_axis
                        slope= (app.AD_y2-app.AD_y1)/(app.AD_x2-app.AD_x1);
                        angle = atan(slope)*(180/pi);
                        app.obliq = imrotate(obliqueslice(app.volume,point1,normal,"OutputSize","full"),angle);

                        imshow(app.obliq,[],'Parent',app.UIAxes4)
                end
            end


            function cronal_from_axial(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,2));
                        app.A_y =slice; %update postion of Axial Horizontal
                        %Change Coronal slice
                        app.Coronal = imrotate((permute(app.volume(slice,:,:),[2 3 1])),90); %Move in the Y direction
                        imshow(app.Coronal,[],'Parent',app.UIAxes2)
                        CoronallLines (app,app.C_x,app.C_y) %Redraw cronal lines

                        %Connect axial Horizontal with Sagittal Vertical
                        app.S_x = slice;
                        delete (app.Sagittal_Vertical)
                        delete (app.Sagittal_Horizontal)
                        SagittalLines (app,app.S_x,app.S_y)

                end

            end


            function saggital_from_axial(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,1));
                        app.A_x = slice; %update postion of Axial Vertical

                        %Change Sagittal slice
                        app.Sagittal = imrotate((permute(app.volume(:,slice,:),[1 3 2])),90); %Move in the X direction
                        imshow(app.Sagittal,[],'Parent',app.UIAxes3)
                        SagittalLines (app,app.S_x,app.S_y) %Redraw sagittal lines

                        %Connect axial Vertical with Cronal Vertical
                        app.C_x = slice;
                        delete(app.Coronal_Vertical)
                        delete(app.Coronal_Horizontal)
                        CoronallLines (app,app.C_x,app.C_y)

                end
            end

        end

        %%%%%%%%%%%%%%%%%%%Draw and Detect moving of Sagittal lines and show their effects on other planes%%%%%%%%%%%%%%%%%%%

        function SagittalLines(app,x,y)
            % draw lines on Sagittal plane
            app.Sagittal_Horizontal = drawline("Parent",app.UIAxes3,'Position',[-1000 y;1000 y],"Color","red","InteractionsAllowed",'translate');
            app.Sagittal_Vertical = drawline("Parent",app.UIAxes3,'Position',[x -1000;x 1000],"Color","blue","InteractionsAllowed",'translate');
            addlistener(app.Sagittal_Horizontal,'ROIMoved',@axial_from_saggital);
            addlistener(app.Sagittal_Vertical,'ROIMoved',@cronal_from_saggital);


            function axial_from_saggital(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,2));
                        app.S_y = slice;  %update postion of Sagittal Horizontal

                        %Change Axial slice
                        app.Axial = app.volume(:, :,(size(app.volume,3)-slice));
                        imshow(app.Axial,[],'Parent',app.UIAxes1)
                        AxialLines (app,app.A_x,app.A_y,app.AD_x1,app.AD_y1,app.AD_x2,app.AD_y2) %Redraw Axial lines

                        %Connect sagittal Horizontal with Cronal Horizontal
                        app.C_y = slice;
                        delete (app.Coronal_Horizontal)
                        delete (app.Coronal_Vertical)
                        CoronallLines (app,app.C_x,app.C_y)


                end
            end


            function cronal_from_saggital(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,1));
                        app.S_x = slice; %update postion of Sagittal Vertical

                        %Change Cronal slice
                        app.Coronal = imrotate((permute(app.volume(slice,:,:),[2 3 1])),90); %Move in the Y direction
                        imshow(app.Coronal,[],'Parent',app.UIAxes2)
                        CoronallLines (app,app.C_x,app.C_y) %Redraw Cronal lines

                        %Connect sagittal Vertical with Axial Horizontal
                        app.A_y = slice;
                        delete (app.Axial_Horizontal)
                        delete (app.Axial_Vertical)
                        delete (app.Axial_Diagonal)
                        AxialLines (app,app.A_x,app.A_y,app.AD_x1,app.AD_y1,app.AD_x2,app.AD_y2)


                end
            end
        end

        %%%%%%%%%%%%%%%%%%%Draw and Detect moving in Coronal lines and show their effects on other planes%%%%%%%%%%%%%%%%%%%

        function CoronallLines(app,x,y)
            % draw lines on Coronal plane
            app.Coronal_Horizontal = drawline("Parent",app.UIAxes2,'Position',[-1000 y;1000 y],"Color","red","InteractionsAllowed",'translate');
            app.Coronal_Vertical = drawline("Parent",app.UIAxes2,'Position',[x -1000;x 1000],"Color","blue","InteractionsAllowed",'translate');
            addlistener(app.Coronal_Horizontal,'ROIMoved',@axial_from_cronal);
            addlistener(app.Coronal_Vertical,'ROIMoved',@saggital_from_cronal);


            function axial_from_cronal(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,2));
                        app.C_y = slice;  %update postion of Coronal Horizontal

                        %Change Axial slice
                        app.Axial = app.volume(:, :,(size(app.volume,3)-slice));
                        imshow(app.Axial,[],'Parent',app.UIAxes1)
                        AxialLines (app,app.A_x,app.A_y,app.AD_x1,app.AD_y1,app.AD_x2,app.AD_y2) %Redraw Axial lines

                        %Connect cronal Horizontal with sagittal Horizontal
                        app.S_y = slice;
                        delete (app.Sagittal_Horizontal)
                        delete (app.Sagittal_Vertical)
                        SagittalLines (app,app.S_x,app.S_y)

                end
            end


            function saggital_from_cronal(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,1));
                        app.C_x = slice;  %update postion of Coronal Vertical

                        %Change Sgittal slice
                        app.Sagittal = imrotate((permute(app.volume(:,slice,:),[1 3 2])),90); %Move in the X direction
                        imshow(app.Sagittal,[],'Parent',app.UIAxes3)
                        SagittalLines (app,app.S_x,app.S_y) %Redraw sagittal lines

                        %Connect cronal Vertical with Axial Vertical
                        app.A_x = slice;
                        delete(app.Axial_Vertical)
                        delete(app.Axial_Horizontal)
                        delete (app.Axial_Diagonal)
                        AxialLines (app,app.A_x,app.A_y,app.AD_x1,app.AD_y1,app.AD_x2,app.AD_y2)

                end
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: BrowseButton
        function BrowseButtonPushed(app, event)
            app.BrowseFlag = true;
            app.MeasurmentsDropDown.Value = "     Measurments";
            %%browse image
            filename=uigetdir;
            %%to handle if user preseed cancel browse
            if filename==0
                % user pressed cancel
                return
            end

            dicomlist = dir(fullfile(filename,'*.dcm'));
            app.volume = [];
            for i = 1 : numel(dicomlist) % from 1 to lengh of list
                %loop to read dicom images from dicom list
                I = dicomread(fullfile(filename,dicomlist(i).name));
                % Build 3d volume matrix by concatenating axial plans with each other
                app.volume = cat(3,app.volume, I);
            end

            %% Axial %%
            for i = 1 : (size(app.volume,3)/2)
                % xy slice :
                app.Axial = app.volume(:, :, i); %Move in the Z direction and show all values of xy
            end
            %% Coronal %%
            for i = 1 : (size(app.volume,1)/2)
                % xz slice:
                % permute function to rearrange the order of matrix dimension "to move all values to XY plane" so we can display it
                app.Coronal = imrotate((permute(app.volume(i,:,:),[2 3 1])),90); %Move in the Y direction
            end
            %% Sagittal %%
            for i = 1 : (size(app.volume,2)/2)
                % yz slice:
                app.Sagittal = imrotate((permute(app.volume(:,i,:),[1 3 2])),90); %Move in the X direction

            end

            %% Oblique %%
            point1=[0 0 randi([1 size(app.volume,3)])];
            point2=[size(app.Axial,2) size(app.Axial,1) randi([1 size(app.volume,3)])];
            point3=[size(app.Axial,2) size(app.Axial,1) randi([1 size(app.volume,3)])];
            line1=point2-point1;
            line2=point3-point2;
            normal=cross(line1 ,line2);
            if (normal(1)>0)
                normal(1) = normal(1)*-1;
            end

            if (normal(2)<0)
                normal(2) = normal(2)*-1;
            end
            app.obliq=imrotate(obliqueslice(app.volume,point1,normal,'OutputSize',"full"),45);

            %Show axial, coronal, saggital and obliqu planes at their windows

            imshow(app.Axial,[],'Parent',app.UIAxes1) %square brackets to normalize the values of pixels between 0 - 255
            disableDefaultInteractivity(app.UIAxes1)
            imshow(app.Coronal,[],'Parent',app.UIAxes2)
            disableDefaultInteractivity(app.UIAxes2)
            imshow(app.Sagittal,[],'Parent',app.UIAxes3)
            disableDefaultInteractivity(app.UIAxes3)
            imshow(app.obliq,[],'Parent',app.UIAxes4)
            disableDefaultInteractivity(app.UIAxes4)


            %Draw lines on each plane at initial place (center)
            app.A_x = size(app.Axial,2)/2 ;
            app.A_y = size(app.Axial,1)/2 ;
            app.AD_x1 = 0;
            app.AD_y1 = 0;
            app.AD_x2 = 2*(app.A_x);
            app.AD_y2 = 2*(app.A_y);
            AxialLines (app,app.A_x,app.A_y,app.AD_x1,app.AD_y1,app.AD_x2,app.AD_y2)


            app.C_x = size(app.Coronal,2)/2 ;
            app.C_y = size(app.Coronal,1)/2 ;
            CoronallLines (app,app.C_x,app.C_y)

            app.S_x = size(app.Sagittal,2)/2 ;
            app.S_y = size(app.Sagittal,1)/2 ;
            SagittalLines (app,app.S_x,app.S_y)

        end

        % Value changed function: MeasurmentsDropDown
        function MeasurmentsDropDownValueChanged(app, event)
            value = app.MeasurmentsDropDown.Value;

            if  (app.BrowseFlag)
                delete(app.ROI);
                app.EditField.Value = 0;
                switch value
                    case ("Lenght of line")

                        delete(app.ROI);

                        app.ROI = drawline("Parent",app.UIAxes4,'Color','magenta');

                        % line_pos = ROI1.Position(2,:)

                        distance = pdist(app.ROI.Position,'euclidean');

                        app.EditField.Value = distance;

                    case ("Angle between lines")
                        delete(app.ROI);
                        
                        app.ROI = drawpolyline("Parent",app.UIAxes4,'Color','yellow');
                        app.ROI.Position;
                        v_1 = [app.ROI.Position(2,:) -  app.ROI.Position(1,:) 0];
                        v_2 = [app.ROI.Position(2,:) -  app.ROI.Position(3,:) 0];
                        Theta = atan2(norm(cross(v_1, v_2)), dot(v_1, v_2))*(180/pi);
                        app.EditField.Value = round(Theta);
                        
                    case ("Area of polygon")
                        delete(app.ROI);

                        app.ROI = drawpolygon("Parent",app.UIAxes4);

                        x = app.ROI.Position(:,1);
                        y = app.ROI.Position(:,2);
                        Polygon_Area = polyarea(x,y);
                        app.EditField.Value = Polygon_Area;
                 
                    case ("Area of ellipse")

                        delete(app.ROI);

                        app.ROI = drawellipse("Parent",app.UIAxes4,"Color",'green');

                        Center = app.ROI.Center;
                        Vertices = app.ROI.Vertices;

                        Pointa = Vertices(1,:);
                        Pointb = Vertices(ceil(size(Vertices,1)/4),:);

                        a = pdist([Pointa; Center],'euclidean');
                        b = pdist([Pointb; Center],'euclidean');


                        Area = pi*a*b;
                        app.EditField.Value = Area;

                end

            else
                uialert(app.UIFigure,'Browse for images first !','Warning','Icon','warning');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0 0 0];
            app.UIFigure.Position = [100 100 916 614];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes1
            app.UIAxes1 = uiaxes(app.UIFigure);
            app.UIAxes1.PlotBoxAspectRatio = [1.98101265822785 1 1];
            app.UIAxes1.XColor = [0.149 0.149 0.149];
            app.UIAxes1.YColor = [0.149 0.149 0.149];
            app.UIAxes1.Color = [0.149 0.149 0.149];
            app.UIAxes1.Position = [18 254 432 266];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            app.UIAxes2.PlotBoxAspectRatio = [1.98101265822785 1 1];
            app.UIAxes2.XColor = [0.149 0.149 0.149];
            app.UIAxes2.YColor = [0.149 0.149 0.149];
            app.UIAxes2.Color = [0.149 0.149 0.149];
            app.UIAxes2.Position = [449 250 432 266];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.UIFigure);
            app.UIAxes4.PlotBoxAspectRatio = [1.98101265822785 1 1];
            app.UIAxes4.XColor = [0.149 0.149 0.149];
            app.UIAxes4.YColor = [0.149 0.149 0.149];
            app.UIAxes4.Color = [0.149 0.149 0.149];
            app.UIAxes4.Position = [449 1 432 266];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            app.UIAxes3.PlotBoxAspectRatio = [1.98101265822785 1 1];
            app.UIAxes3.XColor = [0.149 0.149 0.149];
            app.UIAxes3.YColor = [0.149 0.149 0.149];
            app.UIAxes3.Color = [0.149 0.149 0.149];
            app.UIAxes3.Position = [18 1 432 266];

            % Create BrowseButton
            app.BrowseButton = uibutton(app.UIFigure, 'push');
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);
            app.BrowseButton.Icon = 'computer-display.png';
            app.BrowseButton.BackgroundColor = [1 1 1];
            app.BrowseButton.FontWeight = 'bold';
            app.BrowseButton.Position = [42 556 83 34];
            app.BrowseButton.Text = 'Browse';

            % Create AxialLabel
            app.AxialLabel = uilabel(app.UIFigure);
            app.AxialLabel.HorizontalAlignment = 'center';
            app.AxialLabel.FontSize = 20;
            app.AxialLabel.FontWeight = 'bold';
            app.AxialLabel.FontColor = [1 1 1];
            app.AxialLabel.Position = [191 515 53 24];
            app.AxialLabel.Text = 'Axial';

            % Create SagittalLabel
            app.SagittalLabel = uilabel(app.UIFigure);
            app.SagittalLabel.HorizontalAlignment = 'center';
            app.SagittalLabel.FontSize = 20;
            app.SagittalLabel.FontWeight = 'bold';
            app.SagittalLabel.FontColor = [1 1 1];
            app.SagittalLabel.Position = [179 246 77 24];
            app.SagittalLabel.Text = 'Sagittal';

            % Create CoronalLabel
            app.CoronalLabel = uilabel(app.UIFigure);
            app.CoronalLabel.HorizontalAlignment = 'center';
            app.CoronalLabel.FontSize = 20;
            app.CoronalLabel.FontWeight = 'bold';
            app.CoronalLabel.FontColor = [1 1 1];
            app.CoronalLabel.Position = [606 515 81 24];
            app.CoronalLabel.Text = 'Coronal';

            % Create ObliqueLabel
            app.ObliqueLabel = uilabel(app.UIFigure);
            app.ObliqueLabel.HorizontalAlignment = 'center';
            app.ObliqueLabel.FontSize = 20;
            app.ObliqueLabel.FontWeight = 'bold';
            app.ObliqueLabel.FontColor = [1 1 1];
            app.ObliqueLabel.Position = [607 246 80 24];
            app.ObliqueLabel.Text = 'Oblique';

            % Create MeasurmentsDropDown
            app.MeasurmentsDropDown = uidropdown(app.UIFigure);
            app.MeasurmentsDropDown.Items = {'     Measurments', 'Lenght of line', 'Angle between lines', 'Area of polygon', 'Area of ellipse'};
            app.MeasurmentsDropDown.ValueChangedFcn = createCallbackFcn(app, @MeasurmentsDropDownValueChanged, true);
            app.MeasurmentsDropDown.FontWeight = 'bold';
            app.MeasurmentsDropDown.BackgroundColor = [1 1 1];
            app.MeasurmentsDropDown.Position = [143 556 127 34];
            app.MeasurmentsDropDown.Value = '     Measurments';

            % Create EditField
            app.EditField = uieditfield(app.UIFigure, 'numeric');
            app.EditField.HorizontalAlignment = 'center';
            app.EditField.FontWeight = 'bold';
            app.EditField.Position = [288 560 82 26];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Modalities_FinalProject

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end