# *ispathvalid & mustBeValidPath*: Validate path syntax, type, and extension

[![View on GitHub](https://img.shields.io/badge/GitHub-Repository-171515)](https://github.com/WD40andTape/validatepath)
[![View on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://mathworks.com/matlabcentral/fileexchange/156607-validate-path-syntax-type-and-extension)

The typical use case is to check paths at the start of a script/function before saving/exporting, with human readable feedback if validation fails.

## Syntax

`tf = isvalidpath( inputPath )` checks if the platform can parse the path `inputPath`. Unlike [`isfolder`](https://mathworks.com/help/matlab/ref/isfolder.html) and [`isfile`](https://mathworks.com/help/matlab/ref/isfile.html), it does not verify that the path exists in the file system.

`tf = isvalidpath( inputPath, pathType )` also checks that the location of `inputPath` is either a file or directory.

`tf = isvalidpath( inputPath, "file", validExtensions )` also checks that `inputPath` contains a file extension from a provided set, `validExtensions`.

`[ tf, Log ] = isvalidpath( __ )` additionally returns formatted log messages. `Log.warning` explains why a path is not valid. `Log.info` provides formatting tips. Use the [`disp`](https://mathworks.com/help/matlab/ref/disp.html) function to print the log to the command window.

`mustBeValidPath( inputPath, pathType, validExtensions )` function identically to `isvalidpath` but throws an error if the path format is not valid. `pathType` and `validExtensions` are optional.

## Inputs

| Argument | Description |
| --- | --- |
| `inputPath` | Path to validate.<ul><li>Supported path formats:</li><ul><li>Traditional path, to a file or directory, relative or absolute, e.g., `C:\ffmpeg` and `../file.dat`.</li></ul><li>Unsupported path formats:</li><ul><li>Remote locations, e.g., `s3://bucketname/`.</li><li>UNC paths, e.g., `\\127.0.0.1\temp`.</li><li>DOS device paths, e.g., `\\.\UNC\Server\Share\`.</li><li>URIs, e.g., `file://C:/file.dat` and `http://example.com`.</li><li>All others not listed here.</li></ul></ul>Text scalar, i.e., character vector or string scalar. |
| `pathType` | Valid location type of `inputPath`. Either:<ul><li>`"any"` - **(default)** Any path type is acceptable.</li><li>`"file"` - Only a file path is acceptable, i.e., it must have a file name and a valid extension according to `validExtensions`.</li><li>`"dir"` - Only a directory path is acceptable, i.e., it cannot have a file name or extension.</li><li>`"directory"` - Same as `"dir"`. Text scalar, i.e., character vector or string scalar.</li> |
| `validExtensions` | Specifies which file extensions are valid if the input is a file path. Each entry must be either:<ul><li>**(default)** A period (`.`), representing any extension.</li><li>Text beginning with a period character, e.g., `".mat"`.</li><li>Empty text, `{''}` or `""`, representing no extension.</li><li>`"image"`, representing all raster image extensions MATLAB knows. Run the command `[ imformats().ext ]` to see the list.</li></ul>Character vector, cell array of character vectors, or string array. |

## Outputs

| Argument | Description |
| --- | --- |
| `tf` | Whether the path valid or not according to the above options.<br>Logical scalar. |
| `Log` | Formatted log messages. Struct scalar with the fields:<ul><li>`warning` - String. Explains why the path is not valid, or states when the location is ambiguous, e.g., `"C:\example"` could be either a directory or a file without an extension. Possible `warning` messages:</li><ul><li>Invalid path as per platform rules, e.g., `"dir\dir\dir\:"`.</li><li>Directory path includes a file extension, e.g., `"dir\file.ext"`.</li><li>File path lacks a file name, e.g., `"dir\"`.</li><li>File path missing valid user-specified extension, e.g., `"dir\file"`.</li><li>Path could be a file OR a directory, e.g., `"dir\ambiguous"`. The path may still be valid.</li></ul><li>`info` - String. Contains additional formatting information and explains formatting issues which will not affect the use of path in practice, as they are handled correctly by the platform. Possible `info` messages:</li><ul><li>Path altered by platform during parsing, e.g., any of the below.</li><li>Redundant name elements removed by platform, e.g., `".\dir"`.</li><li>Path has incorrect separators for platform, e.g., `"dir\dir/dir"`.</li><li>Path includes consecutive separators, e.g., `"dir//dir/"`.</li></ul></ul>If there are no messages, the fields of `Log` will be `""`, i.e., a zero length string. Use the [`disp`](https://mathworks.com/help/matlab/ref/disp.html) function to print the messages to the command window, e.g., `disp( Log.warning )`. |

## Example

```MATLAB
load( "spine.mat", "X" )
X = X / max( X, [], "all" );
outputFile = "output\xray.jpg";
validExts = ["" ".mat" "image"];
[ isSave, Log ] = isvalidpath( outputFile, "file", validExts );
if isSave
    [ filePath, ~, fileExt ] = fileparts( outputFile );
    if ~isfolder( filePath )
        [ status, msg ] = mkdir( filePath );
        assert( status == 1, ...
            "Could not make output directory:\n -\t%s", msg )
    end
    try
        if strcmp( fileExt, "" ) || strcmp( fileExt, ".mat" )
            save( outputFile, "X" )
        else
            imwrite( X, outputFile )
        end
        fprintf( "Saved patient scan to '%s'.\n", outputFile )
    catch ME
        warning( ME.identifier, ...
            "Patient scan not saved:\n -\t%s", ME.message )
    end
else
    warning( "Patient scan not saved. " + ...
        "outputFile is not a valid.\n\n%s\n", Log.warning )
end
```

## Notes

Created in 2022b. Compatible with MATLAB release 2019b and later. Compatible with all platforms.

Published under MIT License (see [*LICENSE.txt*](LICENSE.txt)).

Please cite George Abrahams ([GitHub](https://github.com/WD40andTape/), [LinkedIn](https://www.linkedin.com/in/georgeabrahams), [Google Scholar](https://scholar.google.com/citations?user=T_xxZLwAAAAJ)).