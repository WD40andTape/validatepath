function mustBeValidPath( inputPath, pathType, validExtensions )
%MUSTBEVALIDPATH Throw error if path format is not valid.
%   See isvalidpath for full documentation.
% 
%   MUSTBEVALIDPATH( INPUTPATH ), where INPUTPATH is the path to validate.
% 
%   MUSTBEVALIDPATH( INPUTPATH, PATHTYPE ), where PATHTYPE is the valid 
%   path location type, e.g., "file" or "directory".
% 
%   MUSTBEVALIDPATH( INPUTPATH, "file", VALIDEXTENSIONS ), where
%   VALIDEXTENSIONS defines which file extensions to accept. See 
%   documentation for isvalidpath.
% 
%   Created in 2022b. Compatible with 2019b and later. Compatible with all 
%   platforms. Please cite George Abrahams 
%   https://github.com/WD40andTape/validatepath.
% 
%   See also MUSTBEFILE, MUSTBEFOLDER.

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

    [ isValid, Log ] = isvalidpath( inputPath, pathType, validExtensions );
    if ~isValid
        ME = MException( "Validators:InvalidPathFormat", Log.warning );
        throwAsCaller( ME )
    end

end

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