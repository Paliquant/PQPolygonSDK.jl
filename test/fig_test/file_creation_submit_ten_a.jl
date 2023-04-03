# ===========================================================================================================
# test STOCK one ticker, Aggregates

begin
    # build a user model -
    options = Dict{String,Any}()
    options["email"] = "jdv27@cornell.edu"
    # options["apikey"] = "wrong_Key" # do _not_ check in a real API key 
    options["apikey"] = API_KEY
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
    push!(array_of_tickers, "QQQ")
    push!(array_of_tickers, "NFLX")
    push!(array_of_tickers, "SPY")
    endpoint_options["tickers"] = array_of_tickers

    endpoint_options["last_n_records"] = 100000 # default is 30
    endpoint_options["save_frequency"] = 100000

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

begin
    file_name_suffix = "file_creation_submit_ten_a"
    task_name = api(endpoint_model, websocket_url, status_log, data_log, file_name_suffix)
    sleep(30)
    schedule(task_name, InterruptException(), error=true)
    fetch(task_name)
    draw_latency(file_name_suffix)
end