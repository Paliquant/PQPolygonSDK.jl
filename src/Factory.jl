function _add_parameters_to_url_query_string(base::String, options::Dict{String,Any})::String

    # init -
    url_string = base

    parameters = ""
    for (key, value) in options

        # don't add stuff that is nothing
        if (isnothing(value) == false)
            parameters *= "$(key)=$(value)&"
        end
    end

    # cut off trailing &
    query_parameters = parameters[1:end-1]

    # return -
    return url_string * query_parameters
end


function model(userModelType::Type{PQPolygonSDKUserModel}, 
    options::Dict{String,Any})::PQPolygonSDKUserModel

    # initialize -
    user_model = PQPolygonSDKUserModel()

    # for the result of the fields, let's lookup in the dictionary.
    # error state: if the dictionary is missing a value -
    for field_name_symbol ∈ fieldnames(userModelType)
        
        # convert the field_name_symbol to a string -
        field_name_string = string(field_name_symbol)
        
        # check the for the key -
        if (haskey(options,field_name_string) == false)
            throw(ArgumentError("dictionary is missing: $(field_name_string)"))    
        end

        # get the value -
        value = options[field_name_string]

        # set -
        setproperty!(user_model,field_name_symbol,value)
    end

    # return -
    return user_model
end

function model(apiModelType::Type{T}, 
    userModel::PQPolygonSDKUserModel, 
    options::Dict{String,Any})::AbstractPolygonEndpointModel where T<:AbstractPolygonEndpointModel

    # initialize -
    model = eval(Meta.parse("$(apiModelType)()")) # empty endpoint model -

    # grab the apikey from the user object -
    apikey = userModel.apikey
    model.apikey = apikey

    # for the result of the fields, let's lookup in the dictionary.
    # error state: if the dictionary is missing a value -
    for field_name_symbol ∈ fieldnames(apiModelType)
        
        # skip apikey - we already set that
        if (field_name_symbol != :apikey)
            
            # convert the field_name_symbol to a string -
            field_name_string = string(field_name_symbol)
        
            # check the for the key -
            if (haskey(options,field_name_string) == false)
                throw(ArgumentError("dictionary is missing: $(field_name_string)"))    
            end

            # get the value -
            value = options[field_name_string]

            # set -
            setproperty!(model,field_name_symbol,value)
        end
    end

    # return -
    return model
end

function model(contractModelType::Type{T}, 
    options::Dict{String,Any})::AbstractPolygonOptionsContractModel where T <: AbstractPolygonOptionsContractModel
    
    # initialize -
    model = eval(Meta.parse("$(contractModelType)()")) # empty endpoint contract model -

    # for the result of the fields, let's lookup in the dictionary.
    # error state: if the dictionary is missing a value -
    for field_name_symbol ∈ fieldnames(contractModelType)
        
        # convert the field_name_symbol to a string -
        field_name_string = string(field_name_symbol)
        
        # check the for the key -
        if (haskey(options,field_name_string) == false)
            throw(ArgumentError("dictionary is missing: $(field_name_string)"))    
        end

        # get the value -
        value = options[field_name_string]

        # set -
        setproperty!(model,field_name_symbol,value)
    end

    # return -
    return model
end

# -- URL FACTORY METHODS BELOW HERE --------------------------------------------------- #
function url(base::String, model::PolygonTickerNewsEndpointModel; 
    apiversion::Int = 2)::String

    # get data from the API call data -
    apikey = model.apikey
    ticker = model.ticker
    limit = model.limit
    order = model.order

    # check: do we have a published_utc parameter?
    published_utc = nothing
    if (isnothing(model.published_utc) == false)
        published_utc = model.published_utc
    end

    # check: do we have a sort parameter?
    sort = nothing
    if (isnothing(model.sort) == false)
        sort = model.sort
    end

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/news?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
	options_dictionary["apiKey"] = apikey
    options_dictionary["limit"] = limit
    options_dictionary["order"] = order
    options_dictionary["ticker"] = ticker

    # do we have sort data?
    if (isnothing(sort) == false)
        options_dictionary["order"] = sort
    end

    # do we have published_utc data?
    if (isnothing(published_utc) == false)
        options_dictionary["published_utc"] = published_utc
    end

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonDailyOpenCloseEndpointModel; 
    apiversion::Int = 1)::String

    # get data from the API call data -
    adjusted = model.adjusted
    apikey = model.apikey
    date = model.date
    ticker = model.ticker

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/open-close/$(ticker)/$(date)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
	options_dictionary["adjusted"] = adjusted
	options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonGroupedDailyEndpointModel; 
    apiversion::Int = 2)::String

    # get data from the API call data -
    adjusted = model.adjusted
    apikey = model.apikey
    date = model.date

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/aggs/grouped/locale/us/market/stocks/$(date)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
	options_dictionary["adjusted"] = adjusted
	options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonPreviousCloseEndpointModel; 
    apiversion::Int = 2)::String

    # get data from the API call data -
    adjusted = model.adjusted
    apikey = model.apikey
    ticker = model.ticker
    
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/aggs/ticker/$(ticker)/prev?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
	options_dictionary["adjusted"] = adjusted
	options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonAggregatesEndpointModel; 
    apiversion::Int = 2)::String

    # get data from the API call data -
    adjusted = model.adjusted
    limit = model.limit
    sortdirection = model.sortdirection
    apikey = model.apikey
    ticker = model.ticker
    to = model.to
    from = model.from
    multiplier = model.multiplier
    timespan = model.timespan

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/aggs/ticker/$(ticker)/range/$(multiplier)/$(timespan)/$(from)/$(to)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
	options_dictionary["adjusted"] = adjusted
	options_dictionary["sort"] = sortdirection
	options_dictionary["limit"] = limit
	options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

# Options specific endpoints -
function url(base::String, model::PolygonOptionsLastTradeEndpointModel; 
    apiversion::Int = 2)::String

    # get data from the endpoint model -
    ticker = model.ticker
    apikey = model.apikey

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/last/trade/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
	options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonOptionsQuotesEndpointModel; 
    apiversion::Int = 3)::String

    # get data from the endpoint model -
    ticker = model.ticker
    timestamp = model.timestamp
    apikey = model.apikey
    order = model.order
    limit = model.limit
    sort = model.sort

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/quotes/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["timestamp"] = timestamp
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit
    options_dictionary["sort"] = sort

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonOptionsTradesEndpointModel; apiversion::Int = 3)::String
      
    # get data from the endpoint model -
    ticker = model.ticker
    timestamp = model.timestamp
    apikey = model.apikey
    order = model.order
    limit = model.limit
    sort = model.sort
  
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/trades/$(ticker)?"
  
    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["timestamp"] = timestamp
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit
    options_dictionary["sort"] = sort
  
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonOptionsContractSnapshotEndpointModel; 
    apiversion::Int = 3)::String

    # get data from the API call data -
    apikey = model.apikey
    ticker = model.ticker
    underlyingAsset = model.underlyingAsset
 
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/snapshot/options/$(underlyingAsset)/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonOptionsChainSnapshotEndpointModel; 
    apiversion::Int = 3)::String

    # get data from the API call data -
    apikey = model.apikey
    underlyingAsset = model.underlyingAsset
    strike_price = model.strike_price
    expiration_date = model.expiration_date
    contract_type = model.contract_type
    order = model.order
    limit = model.limit
    sort = model.sort

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/snapshot/options/$(underlyingAsset)/?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["strike_price"] = strike_price
    options_dictionary["expiration_date"] = expiration_date
    options_dictionary["contract_type"] = contract_type
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit
    options_dictionary["sort"] = sort    

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end


# Stock specific endpoints -
function url(base::String, model::PolygonStockTradesEndpointModel; 
    apiversion::Int = 3)::String

    # get data from the endpoint model -
    ticker = model.ticker
    timestamp = model.timestamp
    apikey = model.apikey
    order = model.order
    limit = model.limit
    sort = model.sort

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/trades/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["timestamp"] = timestamp
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit
    options_dictionary["sort"] = sort

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

# url methods from ycpan1012 -
function url(base::String, model::PolygonTickerDetailsEndpointModel; #ycpan
    apiversion::Int = 3)::String

    # get data from the API call data -
    apikey = model.apikey
    ticker = model.ticker
    date   = model.date
    
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/tickers/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["date"] = date
    options_dictionary["apiKey"] = apikey
    
    #not all parameters are required, if we have N/A input, we remove it"
    for options ∈ keys(options_dictionary)
        if options_dictionary[options] == "N/A"
            pop!(options_dictionary, options)
        end
    end
    
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonMarketHolidaysEndpointModel; #ycpan
    apiversion::Int = 1)::String

    # get data from the API call data - no data
    apikey = model.apikey    

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/marketstatus/upcoming?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonExchangesEndpointModel; #ycpan
    apiversion::Int = 3)::String #ycpan

    # get data from the API call data -
    apikey = model.apikey
    asset_class = model.asset_class
    locale   = model.locale #ycpan
    
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/exchanges?"
    
    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["asset_class"] = asset_class
    options_dictionary["locale"] = locale
    options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonStockSplitsEndpointModel; #ycpan
    apiversion::Int = 3)::String

    # get data from the API call data -
    apikey = model.apikey
    ticker = model.ticker
    execution_date = model.execution_date
    reverse_split = model.reverse_split
    order = model.order
    limit = model.limit
    sort = model.sort
    
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/splits?"
    
    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["ticker"] = ticker
    options_dictionary["execution_date"] = execution_date
    options_dictionary["reverse_split"] = reverse_split
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit
    options_dictionary["sort"] = sort
    options_dictionary["apiKey"] = apikey
    
    # not all parameters are required, if we have N/A input, we remove it"
    for options ∈ keys(options_dictionary)
        if options_dictionary[options] == "N/A"
            pop!(options_dictionary, options)
        end
    end
            
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonMarketStatusEndpointModel; #ycpan
    apiversion::Int = 1)::String

    # get data from the API call data - no data
    apikey = model.apikey    

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/marketstatus/now?"
    
    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonDividendsEndpointModel; #ycpan
    apiversion::Int = 3)::String

    # get data from the API call data -    
    apikey = model.apikey
    ticker = model.ticker
    ex_dividend_date = model.ex_dividend_date
    record_date = model.record_date
    declaration_date = model.declaration_date
    pay_date = model.pay_date
    frequency = model.frequency
    cash_amount = model.cash_amount
    dividend_type = model.dividend_type
    order = model.order
    limit = model.limit
    sort = model.sort
    
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/dividends?"
    
    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["ticker"] = ticker
    options_dictionary["ex_dividend_date"] = ex_dividend_date
    options_dictionary["record_date"] = record_date
    options_dictionary["declaration_date"] = declaration_date
    options_dictionary["pay_date"] = pay_date
    options_dictionary["frequency"] = frequency
    options_dictionary["cash_amount"] = cash_amount
    options_dictionary["dividend_type"] = dividend_type
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit 
    options_dictionary["sort"] = sort    
    options_dictionary["apiKey"] = apikey
    
    #not all parameters are required, if we have N/A input, we remove it"
    for options ∈ keys(options_dictionary)
        if options_dictionary[options] == "N/A"
            pop!(options_dictionary, options)
        end
    end
            
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonTickersEndpointModel; 
    apiversion::Int = 3)::String #ycpan

            
    # get data from the API call data -
    apikey   = model.apikey
    ticker   = model.ticker
    market   = model.market
    exchange = model.exchange
    cusip    = model.cusip
    cik      = model.cik
    date     = model.date
    search   = model.search
    active   = model.active
    sort     = model.sort
    order    = model.order
    limit    = model.limit
    
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/tickers?"
    
    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["ticker"] = ticker
    options_dictionary["market"] = market
    options_dictionary["exchange"] = exchange
    options_dictionary["cusip"] = cusip
    options_dictionary["cik"] = cik
    options_dictionary["date"] = date
    options_dictionary["search"] = search
    options_dictionary["active"] = active
    options_dictionary["sort"] = sort
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit    
    options_dictionary["apiKey"] = apikey
    
    # not all parameters are required, if we have N/A input, we remove it"
    for options ∈ keys(options_dictionary)
        if options_dictionary[options] == "N/A"
            pop!(options_dictionary, options)
        end
    end
            
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonConditionsEndpointModel; #ycpan
    apiversion::Int = 3)::String #ycpan
    
    # get data from the API call data -
    apikey      = model.apikey
    asset_class = model.asset_class
    data_type   = model.data_type
    id          = model.id
    order       = model.order
    limit       = model.limit
    sort        = model.sort

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/conditions?"
    
    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["asset_class"] = asset_class
    options_dictionary["data_type"] = data_type
    options_dictionary["id"] = id
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit
    options_dictionary["sort"] = sort 
    
    #not all parameters are required, if we have N/A input, we remove it"
    for options ∈ keys(options_dictionary)
        if options_dictionary[options] == "N/A"
            pop!(options_dictionary, options)
        end
    end
            
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonStockFinancialsEndpointModel; #ycpan
    apiversion::String = "X")::String
    
    # get data from the API call data -
    apikey                = model.apikey
    ticker                = model.ticker
    cik                   = model.cik
    company_name          = model.company_name
    sic                   = model.sic
    filing_date           = model.filing_date
    period_of_report_date = model.period_of_report_date
    timeframe             = model.timeframe
    include_sources       = model.include_sources
    order                 = model.order
    limit                 = model.limit
    sort                  = model.sort
    
    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/financials?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["ticker"] = ticker
    options_dictionary["cik"] = cik
    options_dictionary["company_name"] = company_name
    options_dictionary["sic"] = sic    
    options_dictionary["filing_date"] = filing_date
    options_dictionary["period_of_report_date"] = period_of_report_date
    options_dictionary["timeframe"] = timeframe
    options_dictionary["include_sources"] = include_sources
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit
    options_dictionary["sort"] = sort

    #not all parameters are required, if we have N/A input, we remove it"
    for options ∈ keys(options_dictionary)
        if options_dictionary[options] == "N/A"
            pop!(options_dictionary, options)
        end
    end
    
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonTickerTypesEndpointModel; #ycpan
    apiversion::Int = 3)::String

            
    # get data from the API call data -
    apikey   = model.apikey
    asset_class   = model.asset_class
    locale   = model.locale    

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/reference/tickers/types?"
   
    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["asset_class"] = asset_class
    options_dictionary["locale"] = locale
    
    #not all parameters are required, if we have N/A input, we remove it"
    for options ∈ keys(options_dictionary)
        if options_dictionary[options] == "N/A"
            pop!(options_dictionary, options)
        end
    end
            
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonTechnicalIndicatorSMAEndpointModel; 
    apiversion::Int = 1)::String

    # get data from the API call data -
    apikey = model.apikey
    ticker = model.ticker
    timespan = model.timespan
    timestamp = model.timestamp
    adjusted = model.adjusted
    window = model.window
    series_type = model.series_type
    expand_underlying = model.expand_underlying
    order = model.order
    limit = model.limit

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/indicators/sma/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["timespan"] = timespan
    options_dictionary["timestamp"] = timestamp
    options_dictionary["adjusted"] = adjusted
    options_dictionary["window"] = window
    options_dictionary["series_type"] = series_type
    options_dictionary["expand_underlying"] = expand_underlying
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonTechnicalIndicatorEMAEndpointModel; 
    apiversion::Int = 1)::String

    # get data from the API call data -
    apikey = model.apikey
    ticker = model.ticker
    timespan = model.timespan
    timestamp = model.timestamp
    adjusted = model.adjusted
    window = model.window
    series_type = model.series_type
    expand_underlying = model.expand_underlying
    order = model.order
    limit = model.limit

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/indicators/ema/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["timespan"] = timespan
    options_dictionary["timestamp"] = timestamp
    options_dictionary["adjusted"] = adjusted
    options_dictionary["window"] = window
    options_dictionary["series_type"] = series_type
    options_dictionary["expand_underlying"] = expand_underlying
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonTechnicalIndicatorMACDEndpointModel; 
    apiversion::Int = 1)::String

    # get data from the API call data -
    apikey = model.apikey
    ticker = model.ticker
    timespan = model.timespan
    timestamp = model.timestamp
    adjusted = model.adjusted
    short_window = model.short_window
    long_window = model.long_window
    signal_window = model.signal_window
    series_type = model.series_type
    expand_underlying = model.expand_underlying
    order = model.order
    limit = model.limit

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/indicators/macd/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["timespan"] = timespan
    options_dictionary["timestamp"] = timestamp
    options_dictionary["adjusted"] = adjusted
    options_dictionary["short_window"] = short_window
    options_dictionary["long_window"] = long_window
    options_dictionary["signal_window"] = signal_window
    options_dictionary["series_type"] = series_type
    options_dictionary["expand_underlying"] = expand_underlying
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit
 
    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end

function url(base::String, model::PolygonTechnicalIndicatorRSIEndpointModel; 
    apiversion::Int = 1)::String

    # get data from the API call data -
    apikey = model.apikey
    ticker = model.ticker
    timespan = model.timespan
    timestamp = model.timestamp
    adjusted = model.adjusted
    window = model.window
    series_type = model.series_type
    expand_underlying = model.expand_underlying
    order = model.order
    limit = model.limit

    # build up the base string -
    base_url = "$(base)/v$(apiversion)/indicators/rsi/$(ticker)?"

    # what keys are passed as parameters?
    options_dictionary = Dict{String,Any}()
    options_dictionary["apiKey"] = apikey
    options_dictionary["timespan"] = timespan
    options_dictionary["timestamp"] = timestamp
    options_dictionary["adjusted"] = adjusted
    options_dictionary["window"] = window
    options_dictionary["series_type"] = series_type
    options_dictionary["expand_underlying"] = expand_underlying
    options_dictionary["order"] = order
    options_dictionary["limit"] = limit

    # return -
    return _add_parameters_to_url_query_string(base_url, options_dictionary)
end
# -- URL FACTORY METHODS ABOVE HERE --------------------------------------------------- #

# -- OPTIONS TICKER FACTORY METHODS BELOW HERE ---------------------------------------- #
function ticker(contractModelObject::T)::String where T <: AbstractPolygonOptionsContractModel

    # get data from the contract model -
    underlying = contractModelObject.underlying
    expiration = contractModelObject.expiration
    K = contractModelObject.strike

    # build components for the options ticker -
    ticker_component = uppercase(underlying)
    YY = year(expiration) - 2000 # hack to get 2 digit year 
    MM = lpad(month(expiration), 2, "0")
    DD = lpad(day(expiration), 2, "0")

    # what type of contract do we have?
    contract_type = "C"
    if (isa(contractModelObject, PolygonPutOptionContractModel) == true)
         contract_type = "P"
    end

    # compute the price code -
    strike_component = lpad(convert(Int64,K*1000), 8, "0")

    # build the ticker string -
    ticker_string = "O:$(ticker_component)$(YY)$(MM)$(DD)$(contract_type)$(strike_component)"
    
    # return -
    return ticker_string
end
# -- OPTIONS TICKER FACTORY METHODS ABOVE HERE ---------------------------------------- #

# -- Websocket connection utility METHODS --------------------------------------------- #
function input2json_string(instructions_tuple::Tuple)::String
    
    # initialize the input json 
    instructions_dict = Dict{Symbol, String}()
    instructions_dict[:action] = instructions_tuple[1]
    
    if length(instructions_tuple) == 2
        
        # this part perfroms auth from the very first step
        instructions_dict[:params] = instructions_tuple[2]
    else

        # this art perfroms the ticker subscription
        tickers = map(strip, instructions_tuple[3])

        # add prefix for each Ticker
        arr = map(x -> instructions_tuple[2] * "." * x, tickers)

        # join together 
        param_value = join(arr, ", ")

        instructions_dict[:params] = param_value
    end

    # return processed instuctions in json format
    return JSON.json(instructions_dict)

end

function set_up_input_instructions(model::T)::Vector{String} where T<:AbstractPolygonEndpointModel

    # assign parameter locally
    apiKey = model.apikey
    event_type = model.event_type
    tickers = model.tickers

    # initialize input instruction, which will be used for WSS communication
    res_instructions = []

    # set up authentation for websocket connection
    input_tuple_auth = ("auth", apiKey)
    push!(res_instructions, input2json_string(input_tuple_auth))

    # set up tickers for websocket subscription
    input_tuple_param = ("subscribe", event_type, tickers)
    push!(res_instructions, input2json_string(input_tuple_param))

    return res_instructions

end

# -- Websocket connection utility METHODS above here --------------------------------------------- #
