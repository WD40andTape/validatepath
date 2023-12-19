function [ tf, Log ] = isvalidpath( inputPath, pathType, validExtensions )
%ISVALIDPATH Check if a path format is valid.
%   TF = ISVALIDPATH( INPUTPATH ) checks if the platform can parse the
%   path INPUTPATH. Unlike ISFOLDER and ISFILE, it does not verify that the 
%   path exists in the file system.
% 
%   TF = ISVALIDPATH( INPUTPATH, PATHTYPE ) also checks that the location
%   of INPUTPATH is either a file or directory.
% 
%   TF = ISVALIDPATH( INPUTPATH, "file", VALIDEXTENSIONS ) also checks 
%   that INPUTPATH contains a file extension from a provided set, 
%   VALIDEXTENSIONS.
% 
%   [ TF, LOG ] = ISVALIDPATH( ___ ) additionally returns formatted log 
%   messages. LOG.warning explains why a path is not valid. LOG.info
%   provides formatting tips. Use the DISP function to print the log to 
%   the command window.
% 
%   Inputs:
%     - INPUTPATH
%           Path to validate.
%           Supported path formats:
%            -  Traditional path, to a file or directory, relative or 
%               absolute, e.g., "C:\ffmpeg" and "../file.dat".
%           Unsupported path formats:
%            -  Remote locations, e.g., "s3://bucketname/".
%            -  UNC paths, e.g., "\\127.0.0.1\temp".
%            -  DOS device paths, e.g., "\\.\UNC\Server\Share\".
%            -  URIs, e.g., "file://C:/file.dat" and "http://example.com".
%            -  All others not listed here.
%           Text scalar, i.e., character vector or string scalar.
%     - PATHTYPE
%           Valid location type of INPUTPATH. Either:
%           "any"       - (default) Any path type is acceptable.
%           "file"      - Only a file path is acceptable, i.e., it must
%                         have a file name and a valid extension according
%                         to VALIDEXTENSIONS.
%           "dir"       - Only a directory path is acceptable, i.e., it 
%                         cannot have a file name or extension.
%           "directory" - Same as "dir".
%           Text scalar, i.e., character vector or string scalar.
%     - VALIDEXTENSIONS
%           Specifies which file extensions are valid if the input 
%           is a file path. Each entry must be either:
%            -  (default) A period (.), representing any extension.
%            -  Text beginning with a period character, e.g., ".mat".
%            -  Empty text, {''} or "", representing no extension.
%            -  "image", representing all raster image extensions MATLAB 
%               knows. Run the command [ imformats().ext ] to see the list.
%           Character vector, cell array of character vectors, or string 
%           array.
%   Outputs:
%     - TF
%           Whether the path valid or not according to the above options.
%           Logical scalar.
%     - LOG
%           Formatted log messages. Struct scalar with the fields:
%           warning   - String. Explains why the path is not valid, or
%                       states when the location is ambiguous, e.g., 
%                       "C:\example" could be either a directory or a file 
%                       without an extension. Possible warning messages:
%                         +  Invalid path as per platform rules, e.g., 
%                           "dir\dir\dir\:".
%                         +  Directory path includes a file extension, 
%                            e.g., "dir\file.ext".
%                         +  File path lacks a file name, e.g., "dir\".
%                         +  File path missing valid user-specified 
%                            extension, e.g., "dir\file".
%                         +  Path could be a file OR a directory, e.g., 
%                            "dir\ambiguous". The path may still be valid.
%           info      - String. Contains additional formatting information 
%                       and explains formatting issues which will not
%                       affect the use of path in practice, as they are 
%                       handled correctly by the platform. Possible info 
%                       messages:
%                         +  Path altered by platform during parsing, e.g., 
%                            any of the below.
%                         +  Redundant name elements removed by platform, 
%                            e.g., ".\dir".
%                         +  Path has incorrect separators for platform, 
%                            e.g., "dir\dir/dir".
%                         +  Path includes consecutive separators, e.g., 
%                            "dir//dir/".
%           If there are no messages, the fields of LOG will be "", i.e., 
%           a zero length string. Use the DISP function to print the 
%           messages to the command window, e.g., disp( LOG.warning ).
% 
%   Example:
%       load( "spine.mat", "X" )
%       X = X / max( X, [], "all" );
%       outputFile = "output\xray.jpg";
%       validExts = ["" ".mat" "image"];
%       [ isSave, Log ] = isvalidpath( outputFile, "file", validExts );
%       if isSave
%           [ filePath, ~, fileExt ] = fileparts( outputFile );
%           if ~isfolder( filePath )
%               [ status, msg ] = mkdir( filePath );
%               assert( status == 1, ...
%                   "Could not make output directory:\n -\t%s", msg )
%           end
%           try
%               if strcmp( fileExt, "" ) || strcmp( fileExt, ".mat" )
%                   save( outputFile, "X" )
%               else
%                   imwrite( X, outputFile )
%               end
%               fprintf( "Saved patient scan to '%s'.\n", outputFile )
%           catch ME
%               warning( ME.identifier, ...
%                   "Patient scan not saved:\n -\t%s", ME.message )
%           end
%       else
%           warning( "Patient scan not saved. " + ...
%               "outputFile is not a valid.\n\n%s\n", Log.warning )
%       end
% 
%   Created in 2022b. Compatible with 2019b and later. Compatible with all 
%   platforms. Please cite George Abrahams 
%   https://github.com/WD40andTape/validatepath.
% 
%   See also ISFILE, ISFOLDER, FILEPARTS, DISP, MKDIR.

%   Published under MIT License (see LICENSE.txt).
%   Copyright (c) 2023 George Abrahams.
%   - https://github.com/WD40andTape/
%   - https://www.linkedin.com/in/georgeabrahams/
%   - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

    arguments
        inputPath { mustBeTextScalar }
        pathType { mustBeTextScalar, mustBeMember( pathType, ...
            [ "any", "file", "dir", "directory" ] ) } = "any"
        validExtensions { mustBeText, mustBeValidExtInput } = "."
    end

    tf = true;
    Log = struct( "warning", "", "info", "" );
    if strlength( inputPath ) > 0
        % Java's File.toPath() throws an InvalidPathException error
        % if a Path object cannot be constructed from the path string.
        % An InvalidPathException may be thrown because the path string 
        % contains invalid characters, or the path string is invalid for 
        % other file system specific reasons.
        % InvalidPathException.getReason() returns a string explaining 
        % why the input string was rejected.
        % InvalidPathException.getIndex() returns an index into the 
        % input string of the position at which the error occurred, 
        % or -1 if this position is not known.
        % https://docs.oracle.com/javase/7/docs/api/java/io/File.html#toPath()
        % https://docs.oracle.com/javase/7/docs/api/java/nio/file/InvalidPathException.html
        % https://docs.oracle.com/javase/7/docs/api/java/nio/file/Path.html#normalize()
        try
            path = java.io.File( inputPath ).toPath;
            pathParsed = string( path );
            if ~strcmp( inputPath, pathParsed )
                logStr = logparsedpath( pathParsed );
                Log = append2log( Log, logStr, "info" );
            end
            pathNormalized = path.normalize;
            if ~strcmp( inputPath, pathNormalized )
                logStr = lognormalizedpath( pathNormalized );
                Log = append2log( Log, logStr, "info" );
            end
        catch MEjava
            tf = false;
            logStr = logbadpath( MEjava );
            Log = append2log( Log, logStr, "warning" );
        end
        [ ~, logStr ] = iswrongseperators( inputPath );
        Log = append2log( Log, logStr, "info" );
        [ ~, logStr ] = isrepeatedseperators( inputPath );
        Log = append2log( Log, logStr, "info" );
        % If the platform can't parse the path, we stand no chance. In 
        % this case, log no further explanation.
        if tf && ~strncmp( pathType, "any", 1 )
            [ ~, name, ext ] = fileparts( inputPath );
            if strncmp( pathType, "any", 1 ) && strlength( ext ) > 0
                pathType = "file";
            end
            if strncmp( pathType, "directory", 1 )
                if strlength( ext ) > 0
                    tf = false;
                    logStr = logdirectoryhasextension( ext );
                    Log = append2log( Log, logStr, "warning" );
                end
                if strlength( name ) > 0
                    logStr = logambiguouspathtype( pathType );
                    Log = append2log( Log, logStr, "warning" );
                end
            elseif strncmp( pathType, "file", 1 )
                if strlength( name ) == 0
                    tf = false;
                    logStr = logfilenoname;
                    Log = append2log( Log, logStr, "warning" );
                end
                if strlength( ext ) == 0
                    logStr = logambiguouspathtype( pathType );
                    Log = append2log( Log, logStr, "warning" );
                end
                [ isExtValid, logStr ] = ...
                    isextensionvalid( ext, validExtensions );
                tf = tf && isExtValid;
                Log = append2log( Log, logStr, "warning" );
            end
        end
    elseif strncmp( pathType, "file", 1 )
        % An empty path can never be valid for a file.
        tf = false;
        logStr = logfilenoname;
        Log = append2log( Log, logStr, "warning" );
        [ ~, logStr ] = isextensionvalid( "", validExtensions );
        Log = append2log( Log, logStr, "warning" );
    end

end

%% Path validation functions.

function [ tf, msg ] = iswrongseperators( inputPath )
    usedSeperators = regexp( inputPath, ["\\\\" "/"], "once", "match" );
    usedSeperators = rmmissing( usedSeperators );
    tf = numel( usedSeperators ) == 1 && strcmp( filesep, usedSeperators );
    tf = tf || numel( usedSeperators ) > 1;
    msg = [];
    if tf
        msg = logwrongseperators( usedSeperators );
    end
end

function [ tf, msg ] = isrepeatedseperators( inputPath )
    tf = contains( inputPath, "\\" ) || contains( inputPath, "//" );
    % regexp( inputPath, "(?<!^)(\\\\|//)", "once" ) would perform the same
    % test, excluding double slashes at the start of the path, which 
    % indicate servers. However, isvalidpath does not currently support
    % servers.
    msg = [];
    if tf
        msg = logrepeatedseperators;
    end
end

function [ tf, msg ] = isextensionvalid( ext, validExts )
    [ IsValidType, validExts ] = parseValidExts( validExts );
    % Validate path extension matches a user-provided valid extension.
    tf = any( IsValidType.wildcard, "all" );
    tf = tf || ( strcmp( ".", ext ) && any( IsValidType.none, "all" ) );
    tf = tf || ismember( ext, validExts );
    msg = [];
    if ~tf
        msg = loginvalidextension( ext, validExts );
    end
end

%% Helper functions.

function log = append2log( log, text, field )
%   - LOG is a struct scalar, text scalar, or empty. If LOG is a struct,
%     the value of its fields must be a text scalar or empty.
%   - ADDLOG is a text scalar, text array, or empty.
%   - FIELD is a text scalar. If LOG is a struct, FIELD is required and 
%     must be a field name of LOG. ADDLOG will be appended to LOG.FIELD.

    text = string( text(:)' );
    text( strlength( text ) == 0 ) = string.empty;
    if isstruct( log )
        if strlength( string( log.(field) ) ) == 0
            log.(field) = string.empty;
        end
        log.(field) = strjoin( [ log.(field), text ], newline );
    else
        if strlength( string( log ) ) == 0
            log = string.empty;
        end
        log = strjoin( [ log, addLog ], newline );
    end
end

function [ IsType, validExts ] = parseValidExts( validExts )
    IsType.wildcard = ismember( validExts, "." );
    isImage = strcmpi( validExts, "image" );
    if any( IsType.wildcard, "all" )
        validExts = ".";
    elseif any( isImage, "all" )
        validExts( isImage ) = [];
        imageExts = "." + [ imformats().ext ];
        validExts = [ validExts, imageExts ];
    end
    validExts = unique( validExts );
    IsType.wildcard = ismember( validExts, "." );
    IsType.extension = ~IsType.wildcard & startsWith( validExts, "." );
    IsType.none = strlength( validExts ) == 0;
end

%% Function argument validation functions.

function mustBeValidExtInput( validExts )
    IsType = parseValidExts( validExts );
    if ~all( IsType.none | IsType.wildcard | IsType.extension, "all" )
        eidType = "isvalidpath:Validators:InvalidFileExtensionsInput";
        msgType = "Each entry in validExtensions must be either:\n" + ...
            " -\tEmpty text, representing no extension.\n" + ...
            " -\tA period (.), representing any extension.\n" + ...
            " -\tText beginning with a period, e.g., '.mat'.\n" + ...
            " -\t'image', representing all image extensions MATLAB knows.";
        throwAsCaller( MException( eidType, msgType ) )
    end
end

%% Logging functions to format LOG output.

function str = logparsedpath( path )
    str = sprintf( "The platform parsed the path as:\n -\t""%s""", path );
end

function str = lognormalizedpath( path )
    str = sprintf( "The platform eliminated redundant name " + ...
        "elements, as follows:\n -\t""%s""", path );
end

function str = logbadpath( MEjava )
    reason = string( MEjava.ExceptionObject.getReason );
    reason = regexprep( reason, "<(.+?)>", "'$1'" );
    warnIndex = MEjava.ExceptionObject.getIndex + 1;
    if warnIndex > 0
        reason = reason + " at index " + warnIndex;
    end
    str = sprintf( "Path is invalid:\n -\t%s.", reason );
end

function str = logdirectoryhasextension( ext )
    if strcmp( ext, "." )
        ext = "'.'";
    end
    str = sprintf( "Invalid directory:\n" + ...
        " -\tDirectory path cannot have a file extension, but " + ...
        "input path had %s.", ext );
end

function str = logfilenoname
    str = sprintf( "Invalid file name:\n" + ...
        " -\tFile path must contain a non-empty file name." );
end

function str = loginvalidextension( ext, validExts )
    if strlength( ext ) > 0
        inputExtStr = "The provided extension was " + ext;
    else
        inputExtStr = "No file extension was provided";
    end
    [ IsValidType, validExts ] = parseValidExts( validExts );
    if numel( validExts ) == 1
        if IsValidType.none
            validExtStr = "A file extension should not have been provided";
        else
            validExtStr = "The file extension must be " + validExts;
        end
    else
        if any( IsValidType.none, "all" )
            validExts( IsValidType.none ) = [];
            validExts = [ validExts, "or none" ];
        end
        validExtStr = "Valid file extensions are " + ...
            strjoin( validExts, ", " );
    end
    str = sprintf( "Invalid file extension:\n -\t%s.\n -\t%s.", ...
        inputExtStr, validExtStr );
end

function str = logwrongseperators( usedSeperators )
    if numel( usedSeperators ) == 1
        reason = sprintf( "Path uses '%s' but the current platform " + ...
            "uses '%s'", usedSeperators, filesep );
    else % numel( usedSeperators ) == 2
        reason = sprintf( "Path contains both '%s' and '%s'", ...
            usedSeperators(1), usedSeperators(2) );
    end
    str = sprintf( "Incorrect file seperators:\n -\t%s.", reason );
end

function str = logrepeatedseperators
    str = sprintf( "Repeated file separators:\n" + ...
        " -\tDouble slashes ('\\\\' or '//') in the path are ignored." );
end

function str = logambiguouspathtype( pathType )
    if strncmp( pathType, "directory", 1 )
        pathCorrection = filesep;
    else % "file"
        pathCorrection = ".";
    end
    str = sprintf( "Ambiguous path location:\n" + ...
        " -\tCannot detect if the path is a directory or file.\n" + ...
        " -\tAppend a trailing '%s' to resolve the path as a %s.", ...
        pathCorrection, pathType );
end