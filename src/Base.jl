function check(result::Some)::(Union{Nothing,T} where {T<:Any})

    # ok, so check, do we have an error object?
    # Yes: log the error if we have a logger, then throw the error. 
    # No: return the result.value

    # Error case -
    if (isa(something(result), Exception) == true)

        # get the error object -
        error_object = result.value

        # get the error message as a String -
        error_message = sprint(showerror, error_object, catch_backtrace())
        @error(error_message)

        # throw -
        throw(result.value)
    end

    # default -
    return result.value
end

function handle_throwing_errors(error::Exception)
    # get the original error message -
    error_message = sprint(showerror, error, catch_backtrace())
    vl_error_obj = ErrorException(error_message)
    throw(vl_error_obj)
end

function handle_packaging_errors(error::Exception)::Some
    # get the original error message -
    error_message = sprint(showerror, error, catch_backtrace())
    vl_error_obj = ErrorException(error_message)
    
    # Package the error -
    return Some(vl_error_obj)
end