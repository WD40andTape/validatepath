% All of the test cases in this script contain arguments which are invalid 
% for isvalidapth. We therefore test that they all throw an error.

% Invalid function arguments, throw error.
verifyoutput( 1 )
verifyoutput( ["dir" "dir"] )
verifyoutput( "file.txt", ".txt" )
verifyoutput( "file.txt", "file", ["", "txt"] )

fprintf( "All tests passed.\n" )

%% Helper functions.

function verifyoutput( varargin )
    try
        isvalidpath( varargin{:} )
    catch
        return % EARLY RETURN.
    end
    id = "verifyoutput:IncorrectOutput";
    msg = "isvalidpath did not throw an error.";
    throw( MException( id, msg ) );
end