classdef Task3 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        BrowseButton  matlab.ui.control.Button
        UIAxes3       matlab.ui.control.UIAxes
        UIAxes4       matlab.ui.control.UIAxes
        UIAxes2       matlab.ui.control.UIAxes
        UIAxes1       matlab.ui.control.UIAxes
    end


    properties (Access = public)
        Axial % Description
        Coronal
        Sagittal
        Axial_Horizontal
        Axial_Vertical
        Sagittal_Horizontal
        Sagittal_Vertical
        Coronal_Horizontal
        Coronal_Vertical
    end
    methods (Access = public)

        function AxialLines(app,~)
            % draw lines on axial plane
            app.Axial_Horizontal = drawline("Parent",app.UIAxes1,'Position',[-1000 size(app.Axial,1)/2;1000 size(app.Axial,1)/2],"Color","red","InteractionsAllowed",'translate');
            app.Axial_Vertical = drawline("Parent",app.UIAxes1,'Position',[size(app.Axial,2)/2 -1000;size(app.Axial,2)/2 1000],"Color","blue","InteractionsAllowed",'translate');
            Axial_Diagonal = drawline("Parent",app.UIAxes1,'Position',[0 0;size(app.Axial,2) size(app.Axial,1)],"Color","yellow");
        end

        function SagittalLines(app,~)
            % draw lines on Sagittal plane
            app.Sagittal_Horizontal = drawline("Parent",app.UIAxes3,'Position',[-1000 size(app.Sagittal,1)/2;1000 size(app.Sagittal,1)/2],"Color","red","InteractionsAllowed",'translate');
            app.Sagittal_Vertical = drawline("Parent",app.UIAxes3,'Position',[size(app.Sagittal,2)/2 -1000;size(app.Sagittal,2)/2 1000],"Color","blue","InteractionsAllowed",'translate');
        end

        function CoronallLines(app,~)
            % draw lines on Coronal plane
            app.Coronal_Horizontal = drawline("Parent",app.UIAxes2,'Position',[-1000 size(app.Coronal,1)/2;1000 size(app.Coronal,1)/2],"Color","red","InteractionsAllowed",'translate');
            app.Coronal_Vertical = drawline("Parent",app.UIAxes2,'Position',[size(app.Coronal,2)/2 -1000;size(app.Coronal,2)/2 1000],"Color","blue","InteractionsAllowed",'translate');

        end
    end



    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: BrowseButton
        function BrowseButtonPushed(app, event)

            %%browse image
            filename=uigetdir;
            %%to handle if user preseed cancel browse
            if filename==0
                % user pressed cancel
                return
            end

            dicomlist = dir(fullfile(filename,'*.dcm'));
            volume = [];
            for i = 1 : numel(dicomlist) % from 1 to lengh of list
                %loop to read dicom images from dicom list
                I = dicomread(fullfile(filename,dicomlist(i).name));
                % Build 3d volume matrix by concatenating axial plans with each other
                volume = cat(3,volume, I);
            end

            for i = 1 : (size(volume,3)/2)
                % xy slice :
                app.Axial = volume(:, :, i); %Move in the Z direction and show all values of xy
            end

            for i = 1 : (size(volume,1)/2)
                % xz slice:
                % permute function to rearrange the order of matrix dimension "to move all values to XY plane" so we can display it
                app.Coronal = imrotate((permute(volume(i,:,:),[2 3 1])),90); %Move in the Y direction
            end

            for i = 1 : (size(volume,2)/2)
                % yz slice:
                app.Sagittal = imrotate((permute(volume(:,i,:),[1 3 2])),90); %Move in the X direction

            end

            %Show axial, coronal and saggital planes at their windows
            imshow(app.Axial,[],'Parent',app.UIAxes1) %square brackets to normalize the values of pixels between 0 - 255
            disableDefaultInteractivity(app.UIAxes1)
            imshow(app.Coronal,[],'Parent',app.UIAxes2)
            disableDefaultInteractivity(app.UIAxes2)
            imshow(app.Sagittal,[],'Parent',app.UIAxes3)
            disableDefaultInteractivity(app.UIAxes3)


            %Draw lines on each plane
            AxialLines (app)
            CoronallLines (app)
            SagittalLines (app)

            %%%%%%%%%%%%%%%%%%%Detect moving in axial lines and show their effects on other planes%%%%%%%%%%%%%%%%%%%

            addlistener(app.Axial_Horizontal,'ROIMoved',@cronal_from_axial);
            addlistener(app.Axial_Vertical,'ROIMoved',@saggital_from_axial);

            function cronal_from_axial(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,2));
                        app.Coronal = imrotate((permute(volume(slice,:,:),[2 3 1])),90); %Move in the Y direction
                        imshow(app.Coronal,[],'Parent',app.UIAxes2)
                end
                CoronallLines (app)
                addlistener(app.Coronal_Horizontal,'ROIMoved',@axial_from_cronal);
                addlistener(app.Coronal_Vertical,'ROIMoved',@saggital_from_cronal);
            end


            function saggital_from_axial(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,1));
                        app.Sagittal = imrotate((permute(volume(:,slice,:),[1 3 2])),90); %Move in the X direction
                        imshow(app.Sagittal,[],'Parent',app.UIAxes3)
                        SagittalLines (app)
                        addlistener(app.Sagittal_Horizontal,'ROIMoved',@axial_from_saggital);
                        addlistener(app.Sagittal_Vertical,'ROIMoved',@cronal_from_saggital);

                end
            end

            %%%%%%%%%%%%%%%%%%%Detect moving in Coronal lines and show their effects on other planes%%%%%%%%%%%%%%%%%%%

            addlistener(app.Coronal_Horizontal,'ROIMoved',@axial_from_cronal);
            addlistener(app.Coronal_Vertical,'ROIMoved',@saggital_from_cronal);

            function axial_from_cronal(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,2));
                        app.Axial = volume(:, :,(size(volume,3)-slice));
                        imshow(app.Axial,[],'Parent',app.UIAxes1)
                        AxialLines (app)
                        addlistener(app.Axial_Horizontal,'ROIMoved',@cronal_from_axial);
                        addlistener(app.Axial_Vertical,'ROIMoved',@saggital_from_axial);

                end
            end


            function saggital_from_cronal(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,1));
                        app.Sagittal = imrotate((permute(volume(:,slice,:),[1 3 2])),90); %Move in the X direction
                        imshow(app.Sagittal,[],'Parent',app.UIAxes3)
                        SagittalLines (app)
                        addlistener(app.Sagittal_Horizontal,'ROIMoved',@axial_from_saggital);
                        addlistener(app.Sagittal_Vertical,'ROIMoved',@cronal_from_saggital);
                end
            end


            %%%%%%%%%%%%%%%%%%%Detect moving of Sagittal lines and show their effects on other planes%%%%%%%%%%%%%%%%%%%

            addlistener(app.Sagittal_Horizontal,'ROIMoved',@axial_from_saggital);
            addlistener(app.Sagittal_Vertical,'ROIMoved',@cronal_from_saggital);

            function axial_from_saggital(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,2));
                        app.Axial = volume(:, :,(size(volume,3)-slice));
                        imshow(app.Axial,[],'Parent',app.UIAxes1)
                        AxialLines (app)
                        addlistener(app.Axial_Horizontal,'ROIMoved',@cronal_from_axial);
                        addlistener(app.Axial_Vertical,'ROIMoved',@saggital_from_axial);

                end
            end


            function cronal_from_saggital(~,evt)
                evname = evt.EventName;
                switch(evname)
                    case{'ROIMoved'}
                        pos = evt.CurrentPosition;
                        slice = round(pos (1,1));
                        app.Coronal = imrotate((permute(volume(slice,:,:),[2 3 1])),90); %Move in the Y direction
                        imshow(app.Coronal,[],'Parent',app.UIAxes2)
                        CoronallLines (app)
                        addlistener(app.Coronal_Horizontal,'ROIMoved',@axial_from_cronal);
                        addlistener(app.Coronal_Vertical,'ROIMoved',@saggital_from_cronal);

                end
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
            app.UIAxes1.Position = [17 278 432 266];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            app.UIAxes2.PlotBoxAspectRatio = [1.98101265822785 1 1];
            app.UIAxes2.XColor = [0.149 0.149 0.149];
            app.UIAxes2.YColor = [0.149 0.149 0.149];
            app.UIAxes2.Color = [0.149 0.149 0.149];
            app.UIAxes2.Position = [443 281 432 266];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.UIFigure);
            app.UIAxes4.PlotBoxAspectRatio = [1.98101265822785 1 1];
            app.UIAxes4.XColor = [0.149 0.149 0.149];
            app.UIAxes4.YColor = [0.149 0.149 0.149];
            app.UIAxes4.Color = [0.149 0.149 0.149];
            app.UIAxes4.Position = [449 16 432 266];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            app.UIAxes3.PlotBoxAspectRatio = [1.98101265822785 1 1];
            app.UIAxes3.XColor = [0.149 0.149 0.149];
            app.UIAxes3.YColor = [0.149 0.149 0.149];
            app.UIAxes3.Color = [0.149 0.149 0.149];
            app.UIAxes3.Position = [19 16 432 266];

            % Create BrowseButton
            app.BrowseButton = uibutton(app.UIFigure, 'push');
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);
            app.BrowseButton.Icon = 'computer-display.png';
            app.BrowseButton.BackgroundColor = [1 1 1];
            app.BrowseButton.FontWeight = 'bold';
            app.BrowseButton.Position = [59 556 83 34];
            app.BrowseButton.Text = 'Browse';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Task3

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