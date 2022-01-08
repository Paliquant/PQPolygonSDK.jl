function _polygon_error_handler(request_body_dictionary::Dict{String, Any})::Tuple

    # initialize -
    error_response_dictionary = Dict{String,Any}()
    
    # what are my error keys?
    error_keys = keys(request_body_dictionary)
    for key ∈ error_keys
        error_response_dictionary[key] = request_body_dictionary[key]
    end

    # return -
    return (error_response_dictionary, nothing)
end

function _process_previous_close_polygon_call_response(body::String)

    # convert to JSON -
    request_body_dictionary = JSON.parse(body)

    # before we do anything - check: do we have an error?
    status_flag = request_body_dictionary["status"]
    if (status_flag == "ERROR")
        return _polygon_error_handler(request_body_dictionary)
    end

    # initialize -
    header_dictionary = Dict{String,Any}()
    df = DataFrame(

        ticker=String[],
        volume=Float64[],
        volume_weighted_average_price=Float64[],
        open=Float64[],
        close=Float64[],
        high=Float64[],
        low=Float64[],
        timestamp=DateTime[],
        number_of_transactions=Int[]
    )

    # fill in the header dictionary -
    header_keys = [
        "ticker", "queryCount", "adjusted", "status", "request_id", "count"
    ]

    # check - do we have a count (if not resturn zero)
    get!(request_body_dictionary, "count", 0)

    for key ∈ header_keys
        header_dictionary[key] = request_body_dictionary[key]
    end

    # check - do we have a resultsCount field?
    results_count = get!(request_body_dictionary, "resultsCount", 0)
    if (results_count == 0) # we have no results ...
        # return the header and nothing -
        return (header_dictionary, nothing)
    end

    # populate the results DataFrame -
    results_array = request_body_dictionary["results"]
    for result_dictionary ∈ results_array
        
        # build a results tuple -
        result_tuple = (

            ticker = result_dictionary["T"],
            volume = result_dictionary["v"],
            volume_weighted_average_price = result_dictionary["vw"],
            open = result_dictionary["o"],
            close = result_dictionary["c"],
            high = result_dictionary["h"],
            low = result_dictionary["l"],
            timestamp = unix2datetime(result_dictionary["t"]*(1/1000)),
            number_of_transactions = result_dictionary["n"]
        )
    
        # push that tuple into the df -
        push!(df, result_tuple)
    end

    # return -
    return (header_dictionary, df)
end

function _process_aggregates_polygon_call_response(body::String)

    # convert to JSON -
    request_body_dictionary = JSON.parse(body)

    # before we do anything - check: do we have an error?
    status_flag = request_body_dictionary["status"]
    if (status_flag == "ERROR")
        return _polygon_error_handler(request_body_dictionary)
    end

    # initialize -
    header_dictionary = Dict{String,Any}()
    df = DataFrame(

        volume=Float64[],
        volume_weighted_average_price=Float64[],
        open=Float64[],
        close=Float64[],
        high=Float64[],
        low=Float64[],
        timestamp=DateTime[],
        number_of_transactions=Int[]
    )

    # fill in the header dictionary -
    header_keys = [
        "ticker", "queryCount", "adjusted", "status", "request_id", "count"
    ]

    # check - do we have a count (if not resturn zero)
    get!(request_body_dictionary, "count", 0)
    get!(request_body_dictionary, "ticker", "N/A")

    for key ∈ header_keys
        header_dictionary[key] = request_body_dictionary[key]
    end

    # check - do we have a resultsCount field?
    results_count = get!(request_body_dictionary, "resultsCount", 0)
    if (results_count == 0) # we have no results ...
        # return the header and nothing -
        return (header_dictionary, nothing)
    end

    # populate the results DataFrame -
    results_array = request_body_dictionary["results"]
    for result_dictionary ∈ results_array
        
        # set some defaults in case missing fields -
        get!(result_dictionary, "vw", 0.0)
        get!(result_dictionary, "n", 0)

        # build a results tuple -
        result_tuple = (

            volume = result_dictionary["v"],
            volume_weighted_average_price = result_dictionary["vw"],
            open = result_dictionary["o"],
            close = result_dictionary["c"],
            high = result_dictionary["h"],
            low = result_dictionary["l"],
            timestamp = unix2datetime(result_dictionary["t"]*(1/1000)),
            number_of_transactions = result_dictionary["n"]
        )
    
        # push that tuple into the df -
        push!(df, result_tuple)
    end

    # return -
    return (header_dictionary, df)
end

function _process_daily_open_close_call_response(body::String)

    # convert to JSON -
    request_body_dictionary = JSON.parse(body)

    # before we do anything - check: do we have an error?
    status_flag = request_body_dictionary["status"]
    if (status_flag == "ERROR" || status_flag == "NOT_FOUND")
        return _polygon_error_handler(request_body_dictionary)
    end

    # initialize -
    header_dictionary = Dict{String,Any}()
    df = DataFrame(

        ticker=String[],
        volume=Float64[],
        open=Float64[],
        close=Float64[],
        high=Float64[],
        low=Float64[],
        from=Date[],
        afterHours=Float64[],
        preMarket=Float64[]
    )

    header_keys = [
        "status"
    ]
    for key ∈ header_keys
        header_dictionary[key] = request_body_dictionary[key]
    end

    # build a results tuple -
    result_tuple = (

        volume = request_body_dictionary["volume"],
        open = request_body_dictionary["open"],
        close = request_body_dictionary["close"],
        high = request_body_dictionary["high"],
        low = request_body_dictionary["low"],
        from = Date(request_body_dictionary["from"]),
        ticker = request_body_dictionary["symbol"],
        afterHours = request_body_dictionary["afterHours"],
        preMarket = request_body_dictionary["preMarket"]
    )

    # push that tuple into the df -
    push!(df, result_tuple)

    # return -
    return (header_dictionary, df)
end

function _process_options_reference_call_response(body::String)

    # convert to JSON -
    request_body_dictionary = JSON.parse(body)

    # before we do anything - check: do we have an error?
    status_flag = request_body_dictionary["status"]
    if (status_flag == "ERROR")
        return _polygon_error_handler(request_body_dictionary)
    end

    # initialize -
    header_dictionary = Dict{String,Any}()
    df = DataFrame(

        cfi=String[],
        contract_type=String[],
        exercise_style=String[],
        expiration_date=Date[],
        primary_exchange=String[],
        shares_per_contract=Int64[],
        strike_price=Float64[],
        ticker = String[],
        underlying_ticker = String[]
    )

    # fill in the header dictionary -
    header_keys = [
        "status", "request_id", "count", "next_url"
    ]
    for key ∈ header_keys
        header_dictionary[key] = request_body_dictionary[key]
    end

    # populate the results DataFrame -
    results_array = request_body_dictionary["results"]
    for result_dictionary ∈ results_array
        
        # build a results tuple -
        result_tuple = (

            cfi = result_dictionary["cfi"],
            contract_type = result_dictionary["contract_type"],
            exercise_style = result_dictionary["exercise_style"],
            expiration_date = Date(result_dictionary["expiration_date"]),
            primary_exchange = result_dictionary["primary_exchange"],
            shares_per_contract = result_dictionary["shares_per_contract"],
            strike_price = result_dictionary["strike_price"],
            ticker = result_dictionary["ticker"],
            underlying_ticker = result_dictionary["underlying_ticker"]
        )
    
        # push that tuple into the df -
        push!(df, result_tuple)
    end

    # return -
    return (header_dictionary, df)
end

function _process_ticker_news_call_response(body::String)

    # convert to JSON -
    request_body_dictionary = JSON.parse(body)

    # before we do anything - check: do we have an error?
    status_flag = request_body_dictionary["status"]
    if (status_flag == "ERROR")
        return _polygon_error_handler(request_body_dictionary)
    end

    # initialize -
    header_dictionary = Dict{String,Any}()
    df = DataFrame();

    # fill in the header dictionary -
    header_keys = [
        "status", "request_id", "count", "next_url"
    ]
    for key ∈ header_keys
        header_dictionary[key] = request_body_dictionary[key]
    end

    # return -
    return (header_dictionary, df)
end

function _process_ticker_details_call_response(body::String)

    # convert to JSON -
    request_body_dictionary = JSON.parse(body)

    # before we do anything - check: do we have an error?
    if (haskey(request_body_dictionary,"error") == true)
        return _polygon_error_handler(request_body_dictionary)
    end

    # initialize -
    header_dictionary = Dict{String,Any}()
    df = DataFrame(

        logo = String[],
        listdate = Date[],
        cik = String[],
        bloomberg = String[],
        figi = Union{String,Nothing}[],
        lei = Union{String,Nothing}[],
        sic = Int[],
        country = String[],
        industry = String[],
        sector = String[],
        marketcap = Int[],
        employees = Int[],
        phone = String[],
        ceo = String[],
        url = String[],
        description = String[],
        exchange = String[],
        name = String[],
        symbol = String[],
        exchangeSymbol = String[],
        hq_address = String[],
        hq_state = String[],
        hq_country = String[],
        type = String[],
        updated = Date[],
        tags = Array{Array{String,1},1}(),
        similar = Array{Array{String,1},1}()
    );

    # fill in the header dictionary -
    header_keys = [
        "active"
    ];
    for key ∈ header_keys
        header_dictionary[key] = request_body_dictionary[key]
    end

    # updated comes back in "non-standard" mm/dd/yyyy date format -
    date_components = split(request_body_dictionary["updated"],"/")

    # build a results tuple -
    result_tuple = (

        logo = request_body_dictionary["logo"],
        listdate = Date(request_body_dictionary["listdate"]),
        figi = request_body_dictionary["figi"],
        cik = request_body_dictionary["cik"],
        bloomberg = request_body_dictionary["bloomberg"],
        lei = request_body_dictionary["lei"],
        sic = request_body_dictionary["sic"],
        country = request_body_dictionary["country"],
        industry = request_body_dictionary["industry"],
        sector = request_body_dictionary["sector"],
        marketcap = request_body_dictionary["marketcap"],
        employees = request_body_dictionary["employees"],
        phone = request_body_dictionary["phone"],
        ceo = request_body_dictionary["ceo"],
        url = request_body_dictionary["url"],
        description = request_body_dictionary["description"],
        exchange = request_body_dictionary["exchange"],
        name = request_body_dictionary["name"],
        symbol = request_body_dictionary["symbol"],
        exchangeSymbol = request_body_dictionary["exchangeSymbol"],
        hq_address = request_body_dictionary["hq_address"],
        hq_state = request_body_dictionary["hq_state"],
        hq_country = request_body_dictionary["hq_country"],
        type = request_body_dictionary["type"],
        updated = Date("$(date_components[3])-$(date_components[1])-$(date_components[2])"),
        tags = request_body_dictionary["tags"],
        similar = request_body_dictionary["similar"]
    )

    # push that tuple into the df -
    push!(df, result_tuple)

    # return -
    return (header_dictionary, df)
end
