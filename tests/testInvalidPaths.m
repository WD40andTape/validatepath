% All of the test cases in this script are invalid. We therefore test that 
% they all return false with a warning message in the log.

% Incorrect path types, return false.
verifyoutput( "dir\dir\dir\file.", "dir" )
verifyoutput( "dir\dir\dir\file.ext", "dir" )
verifyoutput( "dir\dir\dir\", "file" )
verifyoutput( "", "file" )
verifyoutput( "", "file", "." )

% Incorrect file extensions, return false.
verifyoutput( "dir\dir\dir\file.", "file", ".txt" )
verifyoutput( "dir\dir\dir\file", "file", ".txt" )
verifyoutput( "dir\dir\dir\file.txt", "file", "" )
verifyoutput( "dir\dir\dir\file.mat", "file", [".csv", ".txt"; ".xls", ".xlsx"] )

% Invalid characters in path, return false.
verifyoutput( "dir\dir\dir\:" )
verifyoutput( "dir\dir\dir\*" )
verifyoutput( "dir\dir\dir\?" )
verifyoutput( 'dir\dir\dir\"' )
verifyoutput( "dir\dir\dir\<" )
verifyoutput( "dir\dir\dir\>" )
verifyoutput( "dir\dir\dir\|" )

fprintf( "All tests passed.\n" )

%% Helper functions.

function verifyoutput( varargin )
    [ tf, Log ] = isvalidpath( varargin{:} );
    if tf || strlength( Log.warning ) == 0
        id = "verifyoutput:IncorrectOutput";
        msg = sprintf( "isvalidpath returned the following:\n\n" + ...
            "tf =\n%sLog =\n%s", ...
            formattedDisplayText( tf ), formattedDisplayText( Log ) );
        throw( MException( id, "%s", msg ) );
    end
end