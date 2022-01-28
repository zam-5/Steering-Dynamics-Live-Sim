classdef app1_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        TimeTextArea       matlab.ui.control.TextArea
        TimeTextAreaLabel  matlab.ui.control.Label
        SpeedSpinner       matlab.ui.control.Spinner
        SpeedSpinnerLabel  matlab.ui.control.Label
        StopButton         matlab.ui.control.Button
        StartButton        matlab.ui.control.Button
        Slider             matlab.ui.control.Slider
        SliderLabel        matlab.ui.control.Label
        SpeedmsGauge       matlab.ui.control.SemicircularGauge
        SpeedmsGaugeLabel  matlab.ui.control.Label
        UIAxes             matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        running % Description
    end
    
    methods (Access = private)
        
        function results = tireforce(app, angle)
            x = [-1.0 -.9 -.8 -.7 -.6 -.5 -.4 -2 0 .2  .4 .5 .6 .7 .8 .9 1.0];
            y = [-182 -195 -200 -197 -186 -168 -143 -78 0 78 143 168 186 197 200 195 182];
            
            if angle > 1
                angle = 1;
            end
            if angle < -1
                angle = -1;
            end
            results = interp1(x,y,angle);
        end
        
        function clearPlot(app)
            %Clears the plot and replots the racetrack and car
            cla(app.UIAxes)
            A = readmatrix('Racetrack.xlsx', 'Range', 'B44:C48');
            B = readmatrix('Racetrack.xlsx', 'Range','E48:F48');
            lowerlimit = [A;B];
            plot(app.UIAxes, lowerlimit(:,1), lowerlimit(:,2), 'k');
            
            hold(app.UIAxes, 'on')
            axis(app.UIAxes, [-10 90 -10 30])
            
            A = readmatrix('Racetrack.xlsx', 'Range', 'B49:C53');
            B = readmatrix('Racetrack.xlsx', 'Range', 'E53:F53');
            upperlimit = [A;B];
            plot(app.UIAxes, upperlimit(:,1), upperlimit(:,2), 'k');
            p1 = readmatrix('Racetrack.xlsx', 'Range', 'B55:D55');
            p2 = readmatrix('Racetrack.xlsx', 'Range', 'E55:G55');
            p3 = readmatrix('Racetrack.xlsx', 'Range', 'B57:D57');
            p4 = readmatrix('Racetrack.xlsx', 'Range', 'E57:G57');
            p5 = readmatrix('Racetrack.xlsx', 'Range', 'B55:D55');
            racecar = [p1 1; p2 1; p3 1; p4 1; p5 1];
            plot(app.UIAxes, racecar(:,1), racecar(:,2))
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            %Here the race track and car are plotted on the axes
            A = readmatrix('Racetrack.xlsx', 'Range', 'B44:C48');
            B = readmatrix('Racetrack.xlsx', 'Range','E48:F48');
            lowerlimit = [A;B];
            plot(app.UIAxes, lowerlimit(:,1), lowerlimit(:,2), 'k');
            
            hold(app.UIAxes, 'on')
            axis(app.UIAxes, [-10 90 -10 30])
            
            A = readmatrix('Racetrack.xlsx', 'Range', 'B49:C53');
            B = readmatrix('Racetrack.xlsx', 'Range', 'E53:F53');
            upperlimit = [A;B];
            plot(app.UIAxes, upperlimit(:,1), upperlimit(:,2), 'k');
            p1 = readmatrix('Racetrack.xlsx', 'Range', 'B55:D55');
            p2 = readmatrix('Racetrack.xlsx', 'Range', 'E55:G55');
            p3 = readmatrix('Racetrack.xlsx', 'Range', 'B57:D57');
            p4 = readmatrix('Racetrack.xlsx', 'Range', 'E57:G57');
            p5 = readmatrix('Racetrack.xlsx', 'Range', 'B55:D55');
            racecar = [p1 1; p2 1; p3 1; p4 1; p5 1];
            plot(app.UIAxes, racecar(:,1), racecar(:,2))
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            %Function containing simultion. When app.running is true, the
            %cars position is calculated based on input from the slider and
            %speed input box
            app.running = true;
            
            m = 1000;  % [kg]
            I = 1000;  % [kg*m^2]
            a = 1.0;   % [m] CoM to front axle
            b = 1.4;   % [m] CoM to rear axle
            
            U = app.SpeedSpinner.Value;     % Foward Velocity, [m/s]
            
            x = [0];   % Car x-coordinate [m]
            y = [0];   % Car y-coordinate [m]
            
            v = [0];   % Lateral Velocity [m/s]
            r = [0];   % Yaw Rate
            psi = [0]; % Heading Angle
            
            time_arr = [];
            steer_angle = [];
            
            %alpha_f = [0]; % Front Wheel slip angle
            %alpha_r = [0]; % Rear Wheel slip angle
            
            app.SpeedmsGauge.Value = U;
            
            %Create Car
            p1 = readmatrix('Racetrack.xlsx', 'Range', 'B55:D55');
            p2 = readmatrix('Racetrack.xlsx', 'Range', 'E55:G55');
            p3 = readmatrix('Racetrack.xlsx', 'Range', 'B57:D57');
            p4 = readmatrix('Racetrack.xlsx', 'Range', 'E57:G57');
            p5 = readmatrix('Racetrack.xlsx', 'Range', 'B55:D55');
            racecar = [p1 1; p2 1; p3 1; p4 1; p5 1];
            
            h = 0.1; % Time interval
            tic %Start timing
            count = 0;
            completed = false;
            while app.running
                delta = app.Slider.Value;
                steer_angle(end+1) = delta;
                time_arr(end+1) = count * h;

                alpha_f = (v(end) + a*r(end)) / U - delta;
                alpha_r = (v(end) - b*r(end)) / U;
                
                F_f = app.tireforce(alpha_f);
                F_r = app.tireforce(alpha_r);
                
                dvdt = (-F_f - F_r) / I;
                drdt = (-a*F_f + b*F_r) / I;
                
                v(end+1) = v(end) + h*dvdt;
                r(end+1) = r(end) + h*drdt;
                
                dpsidt = r(end);
                dxdt = U*cos(psi(end)) - v(end)*sin(psi(end));
                dydt = U*sin(psi(end)) + v(end)*cos(psi(end));
                
                psi(end+1) = psi(end) + h*dpsidt;
                x(end+1) = x(end) + h*dxdt;
                y(end+1) = y(end) + h*dydt;
                
                transformation_mat = [
                    cos(psi(end)), sin(psi(end)), 0, 0;
                    -sin(psi(end)), cos(psi(end)), 0, 0;
                    0, 0, 1, 0;
                    x(end), y(end), 0, 1;
                ];
                if x(end) > 80 && y(end) > -4 && y(end) < 4
                    completed = true;
                    break
                end
                
                current_car = racecar * transformation_mat;
                plot(app.UIAxes, current_car(:,1), current_car(:,2))
                
                count = count + 1;
                pause(0.1) 
                
                
            end
            time = toc; %end timing
            if completed
                app.TimeTextArea.Value = strcat("Course completed in: ", string(time), " seconds");
                plot(time_arr, steer_angle*180/pi)
                title('Steering Angle over time')
                xlabel('Time [s]')
                ylabel('Steer Angle [deg]')
            else
                app.TimeTextArea.Value = "Course not completed";
            end
            
            
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            %Stop button: clears plot, stops simulation loop, and clears
            %the timer text box
            app.clearPlot()
            app.running = false;
            app.TimeTextArea.Value = "";
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 797 570];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Race Course')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [1 228 797 343];

            % Create SpeedmsGaugeLabel
            app.SpeedmsGaugeLabel = uilabel(app.UIFigure);
            app.SpeedmsGaugeLabel.HorizontalAlignment = 'center';
            app.SpeedmsGaugeLabel.Position = [119 166 70 22];
            app.SpeedmsGaugeLabel.Text = 'Speed [m/s]';

            % Create SpeedmsGauge
            app.SpeedmsGauge = uigauge(app.UIFigure, 'semicircular');
            app.SpeedmsGauge.Limits = [0 20];
            app.SpeedmsGauge.Tag = 'Speed Gauge';
            app.SpeedmsGauge.Position = [62 113 184 99];

            % Create SliderLabel
            app.SliderLabel = uilabel(app.UIFigure);
            app.SliderLabel.HorizontalAlignment = 'right';
            app.SliderLabel.Position = [568 48 36 22];
            app.SliderLabel.Text = 'Slider';

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.Limits = [-1.5 1.5];
            app.Slider.Orientation = 'vertical';
            app.Slider.Tag = 'Steering';
            app.Slider.Position = [625 57 3 158];

            % Create StartButton
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Position = [351 141 100 22];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [351 112 100 22];
            app.StopButton.Text = 'Stop';

            % Create SpeedSpinnerLabel
            app.SpeedSpinnerLabel = uilabel(app.UIFigure);
            app.SpeedSpinnerLabel.HorizontalAlignment = 'right';
            app.SpeedSpinnerLabel.Position = [77 57 40 22];
            app.SpeedSpinnerLabel.Text = 'Speed';

            % Create SpeedSpinner
            app.SpeedSpinner = uispinner(app.UIFigure);
            app.SpeedSpinner.Step = 0.5;
            app.SpeedSpinner.Limits = [0 Inf];
            app.SpeedSpinner.Position = [132 57 100 22];
            app.SpeedSpinner.Value = 5;

            % Create TimeTextAreaLabel
            app.TimeTextAreaLabel = uilabel(app.UIFigure);
            app.TimeTextAreaLabel.HorizontalAlignment = 'right';
            app.TimeTextAreaLabel.Position = [314 46 35 22];
            app.TimeTextAreaLabel.Text = 'Time:';

            % Create TimeTextArea
            app.TimeTextArea = uitextarea(app.UIFigure);
            app.TimeTextArea.Editable = 'off';
            app.TimeTextArea.Position = [364 29 150 41];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

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