function FM_hyperparameter = split_model_JSR(filename,k)
% Specify the path to your text file
% Read the content of the text file

file_content = fileread(filename);

% Split the content into lines
lines = strsplit(file_content, '\n');

% Initialize a cell array to store the numeric values
bias = {};
w1 = {};
w2 = {};

% Iterate through each line and extract numeric values for lines starting with 'v_i_j'
for i = 1:length(lines)


    if startsWith(lines{i},"i_")
        words = strsplit(lines{i},' ');
        w1{end+1} = str2double(words(2:end));

    elseif startsWith(lines{i}, 'v_')
        % Split the line into words
        words = strsplit(lines{i}, ' ');

        % Extract numeric values from words
        w2{end+1} = str2double(words(2:end));

    elseif startsWith(lines{i}, "bias")
        words = strsplit(lines{i}," ");
        bias{end+1} = str2double(words(2:end));
    end
end

% Convert the cell array to a matrix
FM_hyperparameter.w0 = cell2mat(bias);
FM_hyperparameter.w1 = cell2mat(w1);
FM_hyperparameter.w2 = cell2mat(w2);

% Display the resulting numeric matrix
disp('Numeric Matrix:');
disp(FM_hyperparameter.w1);
disp(FM_hyperparameter.w2);
FM_hyperparameter.w2 = reshape(FM_hyperparameter.w2, k, length(w2));
