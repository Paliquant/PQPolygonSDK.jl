begin
    # build a user model -
    options = Dict{String,Any}()
    options["email"] = "jdv27@cornell.edu"
    # options["apikey"] = "wrong_Key" # do _not_ check in a real API key 
    options["apikey"] = "REAL_APIKEY"
    # build the user model -
    user_model = model(PQPolygonSDKUserModel, options)
    @test user_model.email == options["email"]
    @test user_model.apikey == options["apikey"]
    
    # now that we have the user_model, let's build an endpoint model -
    endpoint_options = Dict{String,Any}()
    endpoint_options["event_type"] = "A"
    
    array_of_tickers = []
    push!(array_of_tickers, "AAPL")
    push!(array_of_tickers, "TSLA")
    push!(array_of_tickers, "MSFT")
    push!(array_of_tickers, "AMZN")
    push!(array_of_tickers, "META")
    push!(array_of_tickers, "AMD")
    push!(array_of_tickers, "GOOG")
    push!(array_of_tickers, "HOOD")
    push!(array_of_tickers, "NFLX")
    push!(array_of_tickers, "NVDA")
    push!(array_of_tickers, "PLTR")
    endpoint_options["tickers"] = array_of_tickers

    endpoint_options["last_n_records"] = 13 # default is 30
    endpoint_options["save_frequency"] = 1000

    endpoint_model = model(PolygonAggregatesPerSecondStocksWebSocketsEndpointModel, user_model, endpoint_options)
    @test endpoint_model.apikey == options["apikey"]
    @test endpoint_model.event_type == endpoint_options["event_type"]
    @test endpoint_model.tickers == endpoint_options["tickers"]
    @test endpoint_model.last_n_records == endpoint_options["last_n_records"]
    @test endpoint_model.save_frequency == endpoint_options["save_frequency"]
    
    
    websocket_url = "wss://socket.polygon.io/stocks"
    
    (status_log, data_log) = build_websocket_response_framework(PolygonAggregatesPerSecondStocksWebSocketsEndpointModel)
    @test status_log == DataFrame(
        event_type=String[],
        status=String[],
        message=String[],)

    @test data_log == DataFrame(
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
        # TODO: Debug
        otc=Union{Nothing,Bool}[],
    )
end

# ===========================================================================================================
# test Stock

@testset "test error exception for wrong url" begin 
    try
        (status_log, data_log) = build_websocket_response_framework(PolygonAggregatesPerSecondStocksWebSocketsEndpointModel)
        api(endpoint_model, "et.polygon.io/stocks", status_log, data_log)
    catch err
        @test occursin("ArgumentError: url et.polygon.io/stocks is not properly formatted", string(err))
    end
end



@testset "test api call no concurrent connection" begin
    (status_log, data_log) = build_websocket_response_framework(PolygonAggregatesPerSecondStocksWebSocketsEndpointModel)
    task_name = api(endpoint_model, websocket_url, status_log, data_log)
    @test typeof(task_name) == Task
    sleep(2)
    schedule(task_name, InterruptException(), error=true)
    sleep(2)
    @test nrow(status_log) == 13
    output_contents = read("files/log_0_status.txt", String)
    expected_output_contents = "event_type, status, message\n"*
    "status, connected, Connected Successfully\n"*
    "status, auth_success, authenticated\n"*
    "status, success, subscribed to: A.AAPL\n"*
    "status, success, subscribed to: A.TSLA\n"*
    "status, success, subscribed to: A.MSFT\n"*
    "status, success, subscribed to: A.AMZN\n"*
    "status, success, subscribed to: A.META\n"*
    "status, success, subscribed to: A.AMD\n"*
    "status, success, subscribed to: A.GOOG\n"*
    "status, success, subscribed to: A.HOOD\n"*
    "status, success, subscribed to: A.NFLX\n"*
    "status, success, subscribed to: A.NVDA\n"*
    "status, success, subscribed to: A.PLTR\n"
    @test output_contents == expected_output_contents
    
end

@testset "test api call with wrong url" begin
    endpoint_model.apikey = "wrong_Key"
    @test endpoint_model.apikey == "wrong_Key" 
    (status_log, data_log) = build_websocket_response_framework(PolygonAggregatesPerSecondStocksWebSocketsEndpointModel)
    task_name = api(endpoint_model, websocket_url, status_log, data_log)
    @test typeof(task_name) == Task
    sleep(2)

    output_contents = read("files/log_0_status.txt", String)
    expected_output_contents = "event_type, status, message\n"*
    "status, connected, Connected Successfully\n"*
    "status, auth_failed, authentication failed\n"


    endpoint_model.apikey = "REAL_APIKEY"
    @test endpoint_model.apikey == "REAL_APIKEY" 
    
end

# ===========================================================================================================