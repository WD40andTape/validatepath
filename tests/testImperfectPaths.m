% Valid but ambiguous paths. As the pathType is specified, these should 
% return true with a warning message in the log.
verifyoutput( "dir\dir\dir\ambiguous", "dir" )
verifyoutput( "dir\dir\dir\ambiguous", "file" )
verifyoutput( "dir\dir\dir\ambiguous", "file", "" )

fprintf( "All tests passed.\n" )

%% Helper functions.

function verifyoutput( varargin )
    [ tf, Log ] = isvalidpath( varargin{:} );
    if ~tf || strlength( Log.warning ) == 0
        id = "verifyoutput:IncorrectOutput";
        msg = sprintf( "isvalidpath returned the following:\n\n" + ...
            "tf =\n%sLog =\n%s", ...
            formattedDisplayText( tf ), formattedDisplayText( Log ) );
        throw( MException( id, "%s", msg ) );
    end
end