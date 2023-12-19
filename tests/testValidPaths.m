% All of the test cases in this script are valid. We therefore test that
% they all return true without a warning message in the log.

% Valid absolute paths.
verifyoutput( "dir\dir\dir\ambiguous" )
verifyoutput( 'dir\dir\dir\ambiguous' )
verifyoutput( "dir\dir\dir\ambiguous", "any" )

% Valid relative paths.
verifyoutput( "\dir\dir\dir\ambiguous" )
verifyoutput( ".\dir\dir\dir\ambiguous" ) % with info message.
verifyoutput( "..\dir\dir\dir\ambiguous" )
verifyoutput( "..\..\.\dir\ambiguous" ) % with info message.

% Valid paths and path types with trailing seperator or '.'.
verifyoutput( "", "dir" )
verifyoutput( "dir\dir\dir\", "dir" ) % with info message.
verifyoutput( "dir\dir\dir\", 'dir' ) % with info message.
verifyoutput( "dir\dir\dir\file.", "file" )

% Correct file extensions.
verifyoutput( "dir\dir\dir\file.", "file", "." )
verifyoutput( "dir\dir\dir\file.", "file", "" )
verifyoutput( "dir\dir\dir\file.txt", "file", ".txt" )
verifyoutput( "dir\dir\dir\file.", "file", [".txt", ""] )
verifyoutput( "dir\dir\dir\file.mat", "file", ...
    [".txt", "."] )
verifyoutput( "dir\dir\dir\file.txt", "file", ...
    [".csv", ".txt"] )
verifyoutput( "dir\dir\dir\file.txt", "file", ...
    {'.csv', '.txt'} )
verifyoutput( "dir\dir\dir\file.txt", "file", ...
    [".csv", ".txt"; ".xls", ".xlsx"] )

% fileExtensions passed when pathType is "dir".
verifyoutput( "dir\dir\dir\", "dir", ".txt" ) % with info message.

% Incorrect seperator in path. These should return true with an info 
% message in the log.
if filesep == '\'
    verifyoutput( "dir/dir/" )
    verifyoutput( "dir\/dir/" )
else
    verifyoutput( "dir\dir\" )
    verifyoutput( "dir\dir/dir/" )
end

% Repeated seperator in path. This should return true with an info message
% in the log.
verifyoutput( "dir/dir//dir/" )

fprintf( "All tests passed.\n" )

%% Helper functions.

function verifyoutput( varargin )
    [ tf, Log ] = isvalidpath( varargin{:} );
    if ~tf || strlength( Log.warning ) ~= 0
        id = "verifyoutput:IncorrectOutput";
        msg = sprintf( "isvalidpath returned the following:\n\n" + ...
            "tf =\n%sLog =\n%s", ...
            formattedDisplayText( tf ), formattedDisplayText( Log ) );
        throw( MException( id, "%s", msg ) );
    end
end