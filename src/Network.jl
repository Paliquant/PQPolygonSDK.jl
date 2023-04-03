function _http_get_call_with_url(url::String)::Some

    try

        # should we check if this string is formatted as a URL?
        if (occursin("https://", url) == false)
            throw(ArgumentError("url $(url) is not properly formatted"))
        end

        # ok, so we are going to make a HTTP GET call with the URL that was passed in -
        # we want to handle the errors on our own, so do NOT have HTTP.j throw an excpetion -
        response = HTTP.request("GET", url; status_exception = false)

        # return the body -
        return Some(String(response.body))
    catch error

        # get the original error message -
        error_message = sprint(showerror, error, catch_backtrace())
        vl_error_obj = ErrorException(error_message)

        # Package the error -
        return Some(vl_error_obj)
    end
end

function _process_polygon_response(model::Type{T}, 
    response::String)::Tuple where T<:AbstractPolygonEndpointModel

    # setup type handler map -> could we put this in a config file to register new handlers?
    type_handler_dict = Dict{Any,Function}()
    type_handler_dict[PolygonAggregatesEndpointModel] = _process_aggregates_polygon_call_response
    type_handler_dict[PolygonOptionsContractReferenceEndpoint] = _process_options_reference_call_response
    type_handler_dict[PolygonPreviousCloseEndpointModel] = _process_previous_close_polygon_call_response
    type_handler_dict[PolygonGroupedDailyEndpointModel] = _process_aggregates_polygon_call_response
    type_handler_dict[PolygonDailyOpenCloseEndpointModel] = _process_daily_open_close_call_response
    type_handler_dict[PolygonTickerNewsEndpointModel] = _process_ticker_news_call_response
    type_handler_dict[PolygonTickerDetailsEndpointModel] = _process_ticker_details_call_response
    type_handler_dict[PolygonStockTradesEndpointModel] = _process_stock_trades_call_response
    
    # options -
    type_handler_dict[PolygonOptionsLastTradeEndpointModel] = _process_options_last_trade_call_response
    type_handler_dict[PolygonOptionsQuotesEndpointModel] = _process_options_quotes_call_response
    type_handler_dict[PolygonOptionsContractSnapshotEndpointModel] = _process_snapshot_option_contract_response
    type_handler_dict[PolygonOptionsTradesEndpointModel] = _process_options_trade_call_response
    type_handler_dict[PolygonOptionsChainSnapshotEndpointModel] = _process_options_chain_snapshot_call_response 

    # technical indicators -
    type_handler_dict[PolygonTechnicalIndicatorSMAEndpointModel] = _process_ti_sma_call_response 
    type_handler_dict[PolygonTechnicalIndicatorEMAEndpointModel] = _process_ti_ema_call_response 
    type_handler_dict[PolygonTechnicalIndicatorMACDEndpointModel] = _process_ti_macd_call_response
    type_handler_dict[PolygonTechnicalIndicatorRSIEndpointModel] = _process_ti_rsi_call_response 

    # handlers from ycpan1012 -
    type_handler_dict[PolygonMarketHolidaysEndpointModel] = _process_market_holidays_call_response #ycpan
    type_handler_dict[PolygonExchangesEndpointModel] = _process_exchanges_call_response #ycpan
    type_handler_dict[PolygonStockSplitsEndpointModel] = _process_stock_splits_call_response #ycpan
    type_handler_dict[PolygonMarketStatusEndpointModel] = _process_market_status_call_response #ycpan
    type_handler_dict[PolygonDividendsEndpointModel] = _process_dividends_call_response #ycpan
    type_handler_dict[PolygonTickersEndpointModel] = _process_tickers_call_response #ycpan
    type_handler_dict[PolygonConditionsEndpointModel] = _process_conditions_call_response #ycpan
    type_handler_dict[PolygonStockFinancialsEndpointModel] = _process_stock_financials_call_response #ycpan
    type_handler_dict[PolygonTickerTypesEndpointModel] = _process_ticker_types_call_response #ycpan
   
    # lookup the type -
    if (haskey(type_handler_dict, model) == true)
        handler_function = type_handler_dict[model]
        return handler_function(response);
    end

    # default -
    return nothing
end

function api(model::Type{T}, complete_url_string::String;
    handler::Function = _process_polygon_response)::Tuple where T<:AbstractPolygonEndpointModel

    # execute -
    result_string = _http_get_call_with_url(complete_url_string) |> check

    # process and return -
    return handler(model, result_string)
end

# ==================================================================================================
# WEBSOCKET API , I put most of my function here, 

function api(model::T, url_string::String, status_log::DataFrame, data_log::DataFrame, file_name_suffix::String
    )::Task where T<:AbstractPolygonEndpointModel

    # connection to websocket
    task = _websocket_call_with_input_instructions(model, url_string, status_log, data_log, file_name_suffix) |> check

    return task
end


function _websocket_call_with_input_instructions(
    model::T, url::String, status_log::DataFrame, data_log::DataFrame, file_name_suffix::String
    ) where T<:AbstractPolygonEndpointModel

    try
        # should we check if this string is formatted as a URL?
        if (occursin("wss://", url) == false)
            throw(ArgumentError("url $(url) is not properly formatted"))
        end

        # initialize instructions to send to websocket
        instructions = set_up_input_instructions(model)

        # initialize some variable
        last_n_records = model.last_n_records
        if isnothing(last_n_records)
            last_n_records = 30
        end
        save_frequency = model.save_frequency

        # initialize channel to make it
        task_channel = Channel{Task}(1)

        # open websocket connection
        @async WSS.open(url) do ws
            
            # when the websocket reveive data, it will push data to "results" array
            task = @async push_received_data_to_results(
                ws, status_log, data_log, last_n_records, save_frequency, typeof(model), file_name_suffix
                )
            
            # the authentation and subscription will be sent to websockets
            push_instructions_to_websocket(ws, instructions)

            # why do we need put task_id to channel and wait them to finish because if we dont wait 
            # them to finish, the WSS will close as soon as it finishes push_instructions_to_websocket
            # and we may want to receive some data after we send instructions;
            put!(task_channel, task)
            fetch(task)
        end

        # we use channel to make sure the task is assigned outside this @async WSS... block
        task = take!(task_channel)
        return Some(task)

    catch error
        handle_packaging_errors(error)
    end
end

function push_received_data_to_results(ws::WSS.WebSocket, status_log::DataFrame, data_log::DataFrame, 
    last_n_records::Union{Nothing,Int}, save_frequency::Union{Nothing,Int}, model_type::Type{T}, file_name_suffix::String
    ) where T<:AbstractPolygonEndpointModel
    
    # for file saving purpose
    status_save = nothing
    data_save = nothing
    if !isnothing(save_frequency)
        status_save = []
        data_save = []
    end
    latency = []
    # latency_id = 1;
    # for file naming purpose
    file_num_status = 0;
    file_num_data = 0;
    

    try    

        while isopen(ws.io)
            # this part will receive message from websocket and save it to result Array
            received_data  = WSS.receive(ws)
            dt_start_processing = now().instant.periods.value
            data = String(received_data)
            # begin
            #     println(latency_id, "\t", data)
            #     latency_id += 1
            # end
            (file_num_status, file_num_data, status_save, data_save) = _save_result_to_var_n_log(model_type, data, status_log, data_log, 
            status_save, data_save, file_num_status, file_num_data, last_n_records, save_frequency)
            dt_finish_processing = now().instant.periods.value
            push!(latency, dt_finish_processing - dt_start_processing)
        end
        
    catch error
        if size(latency) != 0
            save_to_file(latency, file_name_suffix)
        end
        if !isnothing(save_frequency)
            # save the remaining to files if the user set up save frequency
            if size(status_save)[1] != 0
                (status_save, file_num_status) = save_to_file(file_num_status, status_save, join(names(status_log), ", "), "status")
            end
            if size(data_save)[1] != 0
                (data_save, file_num_data) = save_to_file(file_num_data, data_save, join(names(data_log), ", "), "data")
            end
        end

        if isa(error, WSS.WebSocketError) && error.message.status == 1000
            
            println("The WebSocket was closed due to wrong apiKey.")

        elseif isa(error, WSS.WebSocketError) && error.message.status == 1008
            
            println("The WebSocket was closed due to another connection with the same apiKey.")

        elseif isa(error, InterruptException)
            
            println("The WebSocket was closed an interruption.")

        else
            handle_throwing_errors(error)
        end
    end
end

function save_to_file(saved_array::Array{Any, 1}, file_name_suffix::String)
    file_name = pwd()*"/files/log_latency_$(file_name_suffix).txt"
    # write headers
    io = open(file_name, "w")
    
    # write data
    for saved_single in saved_array
        write(io, string(saved_single) * "\n")
    end
    
    close(io)
end

function save_to_file(id::Int64, status_saved_array::Array{Any, 1}, headers::String, file_name::String)
    file_name = pwd()*"/files/log_$(id)_$(file_name).txt"

    # write headers
    io = open(file_name, "w")
    write(io, headers * "\n")

    # write data
    for status_saved_single in status_saved_array
        write(io, join([string(x) for x in status_saved_single], ", ") * "\n")
    end

    close(io)
    id += 1
    return ([], id)
end


function _save_result_to_var_n_log(model_type::Type{T},
    result::String, status_df::DataFrame, data_df::DataFrame, 
    status_save::Union{Nothing, Array{Any, 1}}, data_save::Union{Nothing, Array{Any, 1}}, 
    file_num_status::Int64, file_num_data::Int64, last_n_records::Union{Nothing,Int}, save_frequency::Union{Nothing,Int}
    )::Tuple where T<:AbstractPolygonEndpointModel
    #= 
    error handling does not need to be considered, if we have connection erro, 
    we will put every response from the server to the status log
    =#
    
    # for result ∈ results
        for result_json in JSON.parse(result)
            if "status" in keys(result_json)
                # if states is in the key, save to status log
                # build a status tuple -

                status_tuple = _handling_status_json_result(result_json)

                (file_num_status, status_save) = _handling_saved_var_n_log(
                    status_df, status_tuple, file_num_status, status_save, last_n_records, save_frequency, "status")
            else
                # if states is not in the key, save to data log
                # build a data tuple -
            
                data_tuple = _handling_data_json_result(model_type,result_json)

                (file_num_data, data_save) = _handling_saved_var_n_log(
                    data_df, data_tuple, file_num_data, data_save, last_n_records, save_frequency, "data")
            end
        end
    # end
    return (file_num_status, file_num_data, status_save, data_save)
end

function push_instructions_to_websocket(ws::WSS.WebSocket, instructions::Vector{String})
    try 

        for instruction in instructions
            WSS.send(ws, instruction)
        end

    catch error
        handle_throwing_errors(error)
    end
end

function _handling_status_json_result(result_json::Dict{String, Any})::NamedTuple
    return (
    event_type = result_json["ev"],
    status = result_json["status"],
    message = result_json["message"]
    )
end

function _handling_data_json_result(model_type::Type{T}, result_json::Dict{String, Any}
    )::NamedTuple where T<:AbstractPolygonEndpointModel
    type_handler_dict = Dict{Any,Function}()
    # crypto
    type_handler_dict[PolygonAggregatesPerMinuteCryptoWebSocketsEndpointModel] = _handling_data_json_aggregates_crypto_per_min_wss_result
    
    # stock
    type_handler_dict[PolygonAggregatesPerMinuteStocksWebSocketsEndpointModel] = _handling_data_json_aggregates_stocks_per_min_wss_result
    type_handler_dict[PolygonAggregatesPerSecondStocksWebSocketsEndpointModel] = _handling_data_json_aggregates_stocks_per_sec_wss_result
    type_handler_dict[PolygonTradesStocksWebSocketsEndpointModel] = _handling_data_json_trades_stocks_wss_result
    type_handler_dict[PolygonQuotesStocksWebSocketsEndpointModel] = _handling_data_json_quotes_stocks_wss_result
    type_handler_dict[PolygonLULDStocksWebSocketsEndpointModel] = _handling_data_json_luld_stocks_wss_result


        # lookup the type -
    if (haskey(type_handler_dict, model_type) == true)
        handler_function = type_handler_dict[model_type]
        return handler_function(result_json);
    end
    
    # default -
    return nothing
end

function _handling_data_json_aggregates_crypto_per_min_wss_result(result_json::Dict{String, Any})::NamedTuple
    return (
        event_type = result_json["ev"],
        crypto_pair = result_json["pair"],
        volume = result_json["v"],
        volume_weighted_average_price = result_json["vw"],
        average_trade_size = result_json["z"],
        open = result_json["o"],
        close = result_json["c"],
        high = result_json["h"],
        low = result_json["l"],
        start_time = unix2datetime(result_json["s"]*(1/1000)),
        end_time = unix2datetime(result_json["e"]*(1/1000)),
    )
end

function _handling_data_json_aggregates_stocks_per_min_wss_result(result_json::Dict{String, Any})::NamedTuple
    return (
        event_type = result_json["ev"],
        symbol = result_json["sym"],
        volume = result_json["v"],
        accumulated_volume = result_json["av"],
        official_opening_price = result_json["op"],
        volume_weighted_average_price = result_json["vw"],
        opening_tick_price_cur_win = result_json["o"],
        closing_tick_price_cur_win = result_json["c"],
        highest_tick_price_cur_win = result_json["h"],
        lowest_tick_price_cur_win = result_json["l"],
        today_volume_weighted_average_price = result_json["a"],
        average_trade_size = result_json["z"],
        start_time = unix2datetime(result_json["s"]*(1/1000)),
        end_time = unix2datetime(result_json["e"]*(1/1000)),
        # this will return nothing if OTC is not included
        otc = get!(result_json, "otc", nothing),
    )
end

function _handling_data_json_aggregates_stocks_per_sec_wss_result(result_json::Dict{String, Any})::NamedTuple
    return (
        event_type = result_json["ev"],
        symbol = result_json["sym"],
        volume = result_json["v"],
        accumulated_volume = result_json["av"],
        official_opening_price = result_json["op"],
        volume_weighted_average_price = result_json["vw"],
        opening_tick_price_cur_win = result_json["o"],
        closing_tick_price_cur_win = result_json["c"],
        highest_tick_price_cur_win = result_json["h"],
        lowest_tick_price_cur_win = result_json["l"],
        today_volume_weighted_average_price = result_json["a"],
        average_trade_size = result_json["z"],
        start_time = unix2datetime(result_json["s"]*(1/1000)),
        end_time = unix2datetime(result_json["e"]*(1/1000)),
        # this will return nothing if OTC is not included
        otc = get!(result_json, "otc", nothing),
    )
end

function _handling_data_json_trades_stocks_wss_result(result_json::Dict{String, Any})::NamedTuple
    return (
        event_type = result_json["ev"],
        symbol = result_json["sym"],
        exchange_id = result_json["x"],
        trade_id = result_json["i"],
        tape = result_json["z"],
        price = result_json["p"],
        trade_size = result_json["s"],
        trade_condition = get!(result_json, "c", nothing),
        timestamp = unix2datetime(result_json["t"]*(1/1000)),
        sequence = result_json["q"],
        trf_id = get!(result_json, "trfi", nothing),
        trf_timestamp = haskey(result_json, "trft") ? unix2datetime(result_json["trft"]*(1/1000)) : nothing,
    )
end

function _handling_data_json_quotes_stocks_wss_result(result_json::Dict{String, Any})::NamedTuple
    return (
        event_type = result_json["ev"],
        symbol = result_json["sym"],
        bid_exchange_id = result_json["bx"],
        bid_price = result_json["bp"],
        bid_size = result_json["bs"],
        ask_exchange_id = result_json["ax"],
        ask_price = result_json["ap"],
        ask_size = result_json["as"],
        condition = get!(result_json, "c", nothing),
        indicators = get!(result_json, "i", nothing),
        timestamp = unix2datetime(result_json["t"]*(1/1000)),
        sequence = result_json["q"],
        tape = result_json["z"],
    )
end

function _handling_data_json_luld_stocks_wss_result(result_json::Dict{String, Any})::NamedTuple
    return (
        event_type = result_json["ev"],
        symbol = result_json["T"],
        high_price = result_json["h"],
        low_price = result_json["l"],
        indicators = get!(result_json, "i", nothing),
        tape = result_json["z"],
        timestamp = unix2datetime(result_json["t"]*(1/1000)),
        sequence = result_json["q"],
    )
end

function _handling_saved_var_n_log(df::DataFrame, tuple::NamedTuple, file_num::Int, 
    saved_array::Union{Nothing, Array{Any, 1}}, last_n_records::Int, 
    save_frequency::Union{Nothing,Int}, appendix::String)::Tuple

    push!(df, tuple)
    _keep_last_n_rows(df, last_n_records)
    if !isnothing(save_frequency)
        push!(saved_array, tuple)
        if size(saved_array)[1] > save_frequency 
            (saved_array, file_num) = save_to_file(file_num, saved_array, join(names(df), ", "), appendix)
        end
    end

    return (file_num, saved_array)
end

function build_websocket_response_framework(model::Type{T}
    )::Tuple where T<:AbstractPolygonEndpointModel
    type_handler_dict = Dict{Any,Function}()
    # crypto
    type_handler_dict[PolygonAggregatesPerMinuteCryptoWebSocketsEndpointModel] = _process_aggregates_crypto_per_min_wss_response
    
    # stock 
    type_handler_dict[PolygonAggregatesPerMinuteStocksWebSocketsEndpointModel] = _process_aggregates_stocks_per_min_wss_response
    type_handler_dict[PolygonAggregatesPerSecondStocksWebSocketsEndpointModel] = _process_aggregates_stocks_per_sec_wss_response
    type_handler_dict[PolygonTradesStocksWebSocketsEndpointModel] = _process_trades_stocks_wss_response
    type_handler_dict[PolygonQuotesStocksWebSocketsEndpointModel] = _process_quotes_stocks_wss_response
    type_handler_dict[PolygonLULDStocksWebSocketsEndpointModel] = _process_luld_stocks_wss_response

    # lookup the type -
    if (haskey(type_handler_dict, model) == true)
        handler_function = type_handler_dict[model]
        return handler_function();
    end

    # default -
    return nothing
end

function _process_websocket_status_response()
    return DataFrame(
        event_type=String[],
        status=String[],
        message=String[],
    )
end

function _process_aggregates_stocks_per_min_wss_response()
    status_df = _process_websocket_status_response()
    
    data_df = DataFrame(
        event_type=String[],
        symbol=String[],
        volume=Int[],
        accumulated_volume=Int[],
        official_opening_price=Float64[],
        volume_weighted_average_price=Float64[],
        opening_tick_price_cur_win=Float64[],
        closing_tick_price_cur_win=Float64[],
        highest_tick_price_cur_win=Float64[],
        lowest_tick_price_cur_win=Float64[],
        today_volume_weighted_average_price=Float64[],
        average_trade_size=Int[],
        start_time=DateTime[],
        end_time=DateTime[],
        otc=Union{Nothing,Bool}[],
    )
    return (status_df, data_df)
end

function _process_aggregates_stocks_per_sec_wss_response()
    status_df = _process_websocket_status_response()
    
    data_df = DataFrame(
        event_type=String[],
        symbol=String[],
        volume=Int[],
        accumulated_volume=Int[],
        official_opening_price=Float64[],
        volume_weighted_average_price=Float64[],
        opening_tick_price_cur_win=Float64[],
        closing_tick_price_cur_win=Float64[],
        highest_tick_price_cur_win=Float64[],
        lowest_tick_price_cur_win=Float64[],
        today_volume_weighted_average_price=Float64[],
        average_trade_size=Int[],
        start_time=DateTime[],
        end_time=DateTime[],
        otc=Union{Nothing,Bool}[],
    )
    return (status_df, data_df)
end

function _process_trades_stocks_wss_response()
    status_df = _process_websocket_status_response()
    
    data_df = DataFrame(
        event_type=String[],
        symbol=String[],
        exchange_id=Int[],
        trade_id=String[],
        tape=Int[],
        price=Float64[],
        trade_size=Int[],
        trade_condition=Union{Nothing,Vector{Int}}[],
        timestamp=DateTime[],
        sequence=Int[],
        trf_id=Union{Nothing,Int}[],
        trf_timestamp=Union{Nothing,DateTime}[],
    )
    return (status_df, data_df)
end

function _process_quotes_stocks_wss_response()
    status_df = _process_websocket_status_response()
    
    data_df = DataFrame(
        event_type=String[],
        symbol=String[],
        bid_exchange_id=Int[],
        bid_price=Float64[],
        bid_size=Int[],
        ask_exchange_id=Int[],
        ask_price=Float64[],
        ask_size=Int[],
        condition=Union{Nothing,Int}[],
        indicators=Union{Nothing,Vector{Int}}[],
        timestamp=DateTime[],
        sequence=Int[],
        tape=Int[],
    )
    return (status_df, data_df)
end

function _process_luld_stocks_wss_response()
    status_df = _process_websocket_status_response()
    
    data_df = DataFrame(
        event_type=String[],
        symbol=String[],
        high_price=Float64[],
        low_price=Float64[],
        indicators=Union{Nothing,Vector{Int}}[],
        tape=Int[],
        timestamp=DateTime[],
        sequence=Int[],
    )
    return (status_df, data_df)
end

function _process_aggregates_crypto_per_min_wss_response()
    # initialize -
    status_df = _process_websocket_status_response()
    
    data_df = DataFrame(
        event_type=String[],
        crypto_pair=String[],
        volume=Float64[],
        volume_weighted_average_price=Float64[],
        average_trade_size=Int[],
        open=Float64[],
        close=Float64[],
        high=Float64[],
        low=Float64[],
        start_time=DateTime[],
        end_time=DateTime[],
    )
    return (status_df, data_df)
end

function _keep_last_n_rows(df::DataFrame, last_n_records::Union{Nothing,Int})
    if nrow(df) > last_n_records
        # the root implementation are all vectores, no need to import Deque
        deleteat!(df, 1)
    end
end