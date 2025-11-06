classdef load_dvfs_callback
% This class contains static methods for Simulink mask callbacks
% to load and save DVFS table parameters to/from a .csv file.

    methods(Static)

        % --- LOAD MASK PARAMETERS FROM CSV ---
        % Callback for the 'load_dvfs_button'
        function load_dvfs_button(~)
            [file, path] = uigetfile('*.csv', 'Select a DVFS Profile');
            
            % Check if the user selected a file
            if ischar(file)
                try
                    T = readtable(fullfile(path, file));
                    
                    % Get all available parameter names from the current block
                    % This ensures we only set parameters that exist on this mask
                    availableParams = get_param(gcb, 'MaskNames');
                    
                    % Loop through each row in the loaded CSV
                    for i = 1:height(T)
                        paramName = T.Parameter{i};
                        
                        % --- MODIFICATION ---
                        % Get the value from the cell first
                        valueFromCell = T.Value{i};
                        
                        % Now check the type of the value that was IN the cell
                        if isnumeric(valueFromCell)
                            paramValue = num2str(valueFromCell);
                        else
                            paramValue = valueFromCell; % It's already a string
                        end
                        % --- END MODIFICATION ---

                        % Only set the parameter if it actually exists on this mask
                        if any(strcmp(availableParams, paramName))
                            set_param(gcb, paramName, paramValue);
                        else
                            % Issue a warning if a parameter in the CSV
                            % doesn't exist on the mask.
                            warning('Skipping parameter "%s" as it does not exist on this mask.', paramName);
                        end
                    end
                    
                    % The loop above will now correctly
                    % load the 'loaded_device_name' FROM the CSV file.
                    
                    msgbox(['Parameters loaded from: ' file], 'Success');
                    
                catch ME
                    % Catch any errors during the file reading or setting
                    errordlg(['Failed to load file. Error: ' ME.message], 'Error');
                end
            else
                % User cancelled the 'uigetfile' dialog
                disp('Load operation cancelled.');
            end    
        end


        % --- SAVE MASK PARAMETERS TO CSV ---
        % Callback for the 'save_dvfs_button'
        function save_dvfs_button(~)
            
            try
                % --- MODIFICATION ---
                % Get ALL parameter names defined on the mask.
                % This is more reliable than 'MaskWSVariables'.
                allParamNames = get_param(gcb, 'MaskNames');
                
                % List of parameters to exclude from saving.
                % These are UI elements, not data.
                % 'loaded_device_name' has been REMOVED from this list.
                paramsToExclude = {
                    'DescGroupVar', ...
                    'DescTextVar', ...
                    'ParameterGroupVar', ...
                    'save_dvfs_button', ...
                    'load_dvfs_button'
                };
                
                % Filtered list of parameter names
                paramNamesToSave = setdiff(allParamNames, paramsToExclude, 'stable');

                % Get current values for the filtered list
                paramValues = cell(length(paramNamesToSave), 1);
                for i = 1:length(paramNamesToSave)
                    % --- MODIFICATION ---
                    % Get the parameter's value directly by its name
                    paramValues{i} = get_param(gcb, paramNamesToSave{i});
                end
                
                % Create a table to hold the data
                T = table(paramNamesToSave, paramValues, 'VariableNames', {'Parameter', 'Value'});
                
                % Ask user where to save the file
                [file, path] = uiputfile('*.csv', 'Save DVFS Profile As');
                
                % If the user selected a file, write the table to CSV
                if ischar(file)
                    writetable(T, fullfile(path, file));
                    msgbox(['Parameters saved to: ' file], 'Success');
                else
                    disp('Save operation cancelled.');
                end
            catch ME
                errordlg(['Failed to save file. Error: ' ME.message], 'Error');
            end
        end

    end
end


