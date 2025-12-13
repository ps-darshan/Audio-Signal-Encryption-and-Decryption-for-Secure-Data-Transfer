classdef ChaosAudioApp < matlab.apps.AppBase
    % ChaosAudioApp - App Designer code for dual-algorithm audio encryption/decryption
    %
    % This version ensures the FFT routines receive a key_struct with a .seed
    % field (fftKey.seed), which resolves the "must contain .seed" dot-indexing error.

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        GridLayout                 matlab.ui.container.GridLayout
        OriginalAxes               matlab.ui.control.UIAxes
        ProcessedAxes              matlab.ui.control.UIAxes
        LoadAudioButton            matlab.ui.control.Button
        EncryptButton              matlab.ui.control.Button
        DecryptButton              matlab.ui.control.Button
        PlayOriginalButton         matlab.ui.control.Button
        PlayProcessedButton        matlab.ui.control.Button
        SaveProcessedButton        matlab.ui.control.Button
        GenerateKeyButton          matlab.ui.control.Button
        StatusLabel                matlab.ui.control.Label
        AlgorithmDropDownLabel     matlab.ui.control.Label
        AlgorithmDropDown          matlab.ui.control.DropDown
        ChaosKeyPanel              matlab.ui.container.Panel
        FFTKeyPanel                matlab.ui.container.Panel
        Keyx0EditFieldLabel        matlab.ui.control.Label
        Keyx0EditField             matlab.ui.control.NumericEditField
        KeyrEditFieldLabel         matlab.ui.control.Label
        KeyrEditField              matlab.ui.control.NumericEditField
        SeedLabel                  matlab.ui.control.Label
        SeedEditField              matlab.ui.control.NumericEditField
    end

    properties (Access = private)
        audioData        double = []     
        fs               double = 44100  
        processedAudio   double = []     
        currentFileName  char   = ''     
        playerOriginal   audioplayer    
        playerProcessed  audioplayer    
        keyStruct        struct         
    end

    methods (Access = private)

        function updateStatus(app, msg)
            app.StatusLabel.Text = ["Status: " msg];
            drawnow;
        end

        function plotOriginal(app)
            if isempty(app.audioData)
                cla(app.OriginalAxes);
                return
            end
            t = (0:length(app.audioData)-1)/app.fs;
            plot(app.OriginalAxes, t, app.audioData);
            app.OriginalAxes.Title.String = 'Original Signal';
            app.OriginalAxes.XLabel.String = 'Time (s)';
            app.OriginalAxes.YLabel.String = 'Amplitude';
            xlim(app.OriginalAxes, [0 max(t)]);
        end

        function plotProcessed(app)
            if isempty(app.processedAudio)
                cla(app.ProcessedAxes);
                return
            end
            t = (0:length(app.processedAudio)-1)/app.fs;
            plot(app.ProcessedAxes, t, app.processedAudio);
            app.ProcessedAxes.Title.String = 'Processed Signal';
            app.ProcessedAxes.XLabel.String = 'Time (s)';
            app.ProcessedAxes.YLabel.String = 'Amplitude';
            xlim(app.ProcessedAxes, [0 max(t)]);
        end

        function s = makeChaosKeyFromFields(app)
            % Build chaos key struct from fields
            s.x0 = app.Keyx0EditField.Value;
            s.r  = app.KeyrEditField.Value;
        end
    end

    % Callbacks
    methods (Access = private)

        % Dropdown callback: swap panels
        function AlgorithmDropDownValueChanged(app, event)
            val = app.AlgorithmDropDown.Value;
            if strcmp(val, 'Chaos Map')
                app.ChaosKeyPanel.Visible = 'on';
                app.FFTKeyPanel.Visible = 'off';
            else
                app.ChaosKeyPanel.Visible = 'off';
                app.FFTKeyPanel.Visible = 'on';
            end
        end

        % Load Audio
        function LoadAudioButtonPushed(app, ~)
            try
                [file, path] = uigetfile({'*.wav','WAV files (*.wav)'}, 'Select WAV file');
                if isequal(file,0)
                    app.updateStatus('Load cancelled.');
                    return;
                end
                [y, Fs] = audioread(fullfile(path, file));
                if size(y,2) > 1
                    y = y(:,1);
                end
                app.fs = Fs;
                app.audioData = y;
                app.currentFileName = file;
                app.processedAudio = [];
                app.plotOriginal();
                cla(app.ProcessedAxes);
                app.updateStatus(['File loaded: ' file]);
            catch ME
                app.updateStatus(['Error loading file: ' ME.message]);
            end
        end

        % Encrypt Button
        function EncryptButtonPushed(app, ~)
            if isempty(app.audioData)
                app.updateStatus('No audio loaded.');
                return
            end

            algo = app.AlgorithmDropDown.Value;
            try
                app.updateStatus(['Encrypting using ' algo '...']);

                if strcmp(algo, 'Chaos Map')
                    % Create chaos key struct and call Encrypt_Chaos
                    key = app.makeChaosKeyFromFields();
                    app.keyStruct = key;
                    encrypted = Encrypt_Chaos(app.audioData, key);

                elseif strcmp(algo, 'FFT Phase Scramble')
                    % Create fft key struct with .seed field (to satisfy functions expecting a struct)
                    seed = app.SeedEditField.Value;
                    fftKey = struct();
                    fftKey.seed = seed;
                    app.keyStruct = fftKey;
                    % Call Encrypt_FFT with fftKey (struct with .seed)
                    encrypted = Encrypt_FFT(app.audioData, fftKey);
                else
                    error('Unknown algorithm selected.');
                end

                app.processedAudio = encrypted;
                app.plotProcessed();
                app.updateStatus('Encryption completed.');

            catch ME
                % Show message returned by underlying functions
                app.updateStatus(['Encryption error: ' ME.message]);
            end
        end

        % Decrypt Button
        function DecryptButtonPushed(app, ~)
            if isempty(app.audioData) && isempty(app.processedAudio)
                app.updateStatus('No audio loaded or processed.');
                return
            end

            algo = app.AlgorithmDropDown.Value;
            try
                app.updateStatus(['Decrypting using ' algo '...']);

                % decide source: if processedAudio empty assume file loaded into audioData is encrypted
                if isempty(app.processedAudio)
                    source = app.audioData;
                else
                    source = app.processedAudio;
                end

                if strcmp(algo, 'Chaos Map')
                    key = app.makeChaosKeyFromFields();
                    app.keyStruct = key;
                    decrypted = Decrypt_Chaos(source, key);

                elseif strcmp(algo, 'FFT Phase Scramble')
                    seed = app.SeedEditField.Value;
                    fftKey = struct();
                    fftKey.seed = seed;
                    app.keyStruct = fftKey;
                    decrypted = Decrypt_FFT(source, fftKey);
                else
                    error('Unknown algorithm selected.');
                end

                app.processedAudio = decrypted;
                app.plotProcessed();
                app.updateStatus('Decryption completed.');

            catch ME
                app.updateStatus(['Decryption error: ' ME.message]);
            end
        end

        % Play Original
        function PlayOriginalButtonPushed(app, ~)
            if isempty(app.audioData)
                app.updateStatus('No audio loaded.');
                return
            end
            try
                if ~isempty(app.playerOriginal) && isplaying(app.playerOriginal)
                    stop(app.playerOriginal);
                end
                app.playerOriginal = audioplayer(app.audioData, app.fs);
                play(app.playerOriginal);
                app.updateStatus('Playing original audio...');
            catch ME
                app.updateStatus(['Playback error: ' ME.message]);
            end
        end

        % Play Processed
        function PlayProcessedButtonPushed(app, ~)
            if isempty(app.processedAudio)
                app.updateStatus('No processed audio to play.');
                return
            end
            try
                if ~isempty(app.playerProcessed) && isplaying(app.playerProcessed)
                    stop(app.playerProcessed);
                end
                app.playerProcessed = audioplayer(app.processedAudio, app.fs);
                play(app.playerProcessed);
                app.updateStatus('Playing processed audio...');
            catch ME
                app.updateStatus(['Playback error: ' ME.message]);
            end
        end

        % Save Processed
        function SaveProcessedButtonPushed(app, ~)
            if isempty(app.processedAudio)
                app.updateStatus('No processed audio to save.');
                return
            end
            try
                [file, path] = uiputfile('*.wav', 'Save processed audio as');
                if isequal(file,0)
                    app.updateStatus('Save cancelled.');
                    return
                end
                fullfileName = fullfile(path, file);
                y = app.processedAudio;
                if size(y,2) > 1
                    y = y(:,1);
                end
                audiowrite(fullfileName, y, app.fs);
                app.updateStatus(['Processed file saved: ' file]);
            catch ME
                app.updateStatus(['Save error: ' ME.message]);
            end
        end

        % Generate Key Button
        function GenerateKeyButtonPushed(app, ~)
            algo = app.AlgorithmDropDown.Value;

            if strcmp(algo, 'Chaos Map')
                s = Generate_Chaos_Key();
                app.Keyx0EditField.Value = s.x0;
                app.KeyrEditField.Value  = s.r;
                app.keyStruct = s;
                app.updateStatus('Chaos key generated.');

            elseif strcmp(algo, 'FFT Phase Scramble')
                seed = randi(1e6);
                app.SeedEditField.Value = seed;
                fftKey = struct(); fftKey.seed = seed;
                app.keyStruct = fftKey;
                app.updateStatus(['Random FFT seed generated: ' num2str(seed)]);
            else
                app.updateStatus('Unknown algorithm for key generation.');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 900 550];
            app.UIFigure.Name = 'Chaos Audio Encryption (Dual Algorithm)';

            % Grid layout to hold axes and controls
            app.GridLayout = uigridlayout(app.UIFigure, [7, 6]);
            app.GridLayout.RowHeight = {'1x','fit','fit','fit','fit','fit',30};
            app.GridLayout.ColumnWidth = {'1x','1x','fit','fit','fit','fit'};

            % Original Axes
            app.OriginalAxes = uiaxes(app.GridLayout);
            app.OriginalAxes.Layout.Row = 1;
            app.OriginalAxes.Layout.Column = [1 3];
            title(app.OriginalAxes, 'Original Signal');

            % Processed Axes
            app.ProcessedAxes = uiaxes(app.GridLayout);
            app.ProcessedAxes.Layout.Row = 1;
            app.ProcessedAxes.Layout.Column = [4 6];
            title(app.ProcessedAxes, 'Processed Signal');

            % Load Audio Button
            app.LoadAudioButton = uibutton(app.GridLayout, 'push');
            app.LoadAudioButton.Layout.Row = 2;
            app.LoadAudioButton.Layout.Column = 1;
            app.LoadAudioButton.Text = 'Load Audio';
            app.LoadAudioButton.ButtonPushedFcn = createCallbackFcn(app, @LoadAudioButtonPushed, true);

            % Encrypt Button
            app.EncryptButton = uibutton(app.GridLayout, 'push');
            app.EncryptButton.Layout.Row = 2;
            app.EncryptButton.Layout.Column = 2;
            app.EncryptButton.Text = 'Encrypt';
            app.EncryptButton.ButtonPushedFcn = createCallbackFcn(app, @EncryptButtonPushed, true);

            % Decrypt Button
            app.DecryptButton = uibutton(app.GridLayout, 'push');
            app.DecryptButton.Layout.Row = 2;
            app.DecryptButton.Layout.Column = 3;
            app.DecryptButton.Text = 'Decrypt';
            app.DecryptButton.ButtonPushedFcn = createCallbackFcn(app, @DecryptButtonPushed, true);

            % Play Original Button
            app.PlayOriginalButton = uibutton(app.GridLayout, 'push');
            app.PlayOriginalButton.Layout.Row = 2;
            app.PlayOriginalButton.Layout.Column = 4;
            app.PlayOriginalButton.Text = 'Play Original';
            app.PlayOriginalButton.ButtonPushedFcn = createCallbackFcn(app, @PlayOriginalButtonPushed, true);

            % Play Processed Button
            app.PlayProcessedButton = uibutton(app.GridLayout, 'push');
            app.PlayProcessedButton.Layout.Row = 2;
            app.PlayProcessedButton.Layout.Column = 5;
            app.PlayProcessedButton.Text = 'Play Processed';
            app.PlayProcessedButton.ButtonPushedFcn = createCallbackFcn(app, @PlayProcessedButtonPushed, true);

            % Save Processed Button
            app.SaveProcessedButton = uibutton(app.GridLayout, 'push');
            app.SaveProcessedButton.Layout.Row = 2;
            app.SaveProcessedButton.Layout.Column = 6;
            app.SaveProcessedButton.Text = 'Save Processed Audio';
            app.SaveProcessedButton.ButtonPushedFcn = createCallbackFcn(app, @SaveProcessedButtonPushed, true);

            % Generate Key Button
            app.GenerateKeyButton = uibutton(app.GridLayout,'push');
            app.GenerateKeyButton.Layout.Row = 3;
            app.GenerateKeyButton.Layout.Column = 3;
            app.GenerateKeyButton.Text = 'Generate Key';
            app.GenerateKeyButton.ButtonPushedFcn = createCallbackFcn(app, @GenerateKeyButtonPushed, true);

            % Key x0 Label and Field will be inside ChaosKeyPanel

            % Algorithm Label & Dropdown
            app.AlgorithmDropDownLabel = uilabel(app.GridLayout);
            app.AlgorithmDropDownLabel.Layout.Row = 4;
            app.AlgorithmDropDownLabel.Layout.Column = 1;
            app.AlgorithmDropDownLabel.Text = 'Algorithm:';

            app.AlgorithmDropDown = uidropdown(app.GridLayout);
            app.AlgorithmDropDown.Items = {'Chaos Map','FFT Phase Scramble'};
            app.AlgorithmDropDown.Value = 'Chaos Map';
            app.AlgorithmDropDown.Layout.Row = 4;
            app.AlgorithmDropDown.Layout.Column = 2;
            app.AlgorithmDropDown.ValueChangedFcn = createCallbackFcn(app,@AlgorithmDropDownValueChanged,true);

            % Chaos Key Panel
            app.ChaosKeyPanel = uipanel(app.GridLayout,'Title','Chaos Map Keys');
            app.ChaosKeyPanel.Layout.Row = 5;
            app.ChaosKeyPanel.Layout.Column = [1 6];

            keyGrid = uigridlayout(app.ChaosKeyPanel,[1,4]);
            keyGrid.ColumnWidth = {'fit','1x','fit','1x'};

            app.Keyx0EditFieldLabel = uilabel(keyGrid,'Text','x0:');
            app.Keyx0EditFieldLabel.Layout.Column = 1;

            app.Keyx0EditField = uieditfield(keyGrid,'numeric');
            app.Keyx0EditField.Layout.Column = 2;
            app.Keyx0EditField.Value = 0.127; % example default

            app.KeyrEditFieldLabel = uilabel(keyGrid,'Text','r:');
            app.KeyrEditFieldLabel.Layout.Column = 3;

            app.KeyrEditField = uieditfield(keyGrid,'numeric');
            app.KeyrEditField.Layout.Column = 4;
            app.KeyrEditField.Value = 3.991; % example default

            % FFT Key Panel (overlaps the same area)
            app.FFTKeyPanel = uipanel(app.GridLayout,'Title','FFT Phase Scramble Key');
            app.FFTKeyPanel.Layout.Row = 5;
            app.FFTKeyPanel.Layout.Column = [1 6];

            fftGrid = uigridlayout(app.FFTKeyPanel,[1,2]);
            fftGrid.ColumnWidth = {'fit','1x'};

            app.SeedLabel = uilabel(fftGrid,'Text','Secret Seed:');
            app.SeedLabel.Layout.Column = 1;

            app.SeedEditField = uieditfield(fftGrid,'numeric');
            app.SeedEditField.Layout.Column = 2;
            app.SeedEditField.Value = 12345;

            % Make FFT panel invisible on startup
            app.FFTKeyPanel.Visible = 'off';

            % Status Label
            app.StatusLabel = uilabel(app.GridLayout);
            app.StatusLabel.Layout.Row = 7;
            app.StatusLabel.Layout.Column = [1 6];
            app.StatusLabel.HorizontalAlignment = 'left';
            app.StatusLabel.Text = 'Status: Ready';

            % Show the figure after construction
            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)

        % Construct app
        function app = ChaosAudioApp
            createComponents(app)
            if nargout == 0
                clear app
            end
        end
    end
end
