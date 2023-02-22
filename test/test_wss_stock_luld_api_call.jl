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
    endpoint_options["event_type"] = "LULD"
    
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

    endpoint_model = model(PolygonLULDStocksWebSocketsEndpointModel, user_model, endpoint_options)
    @test endpoint_model.apikey == options["apikey"]
    @test endpoint_model.event_type == endpoint_options["event_type"]
    @test endpoint_model.tickers == endpoint_options["tickers"]
    @test endpoint_model.last_n_records == endpoint_options["last_n_records"]
    @test endpoint_model.save_frequency == endpoint_options["save_frequency"]
    
    
    websocket_url = "wss://socket.polygon.io/stocks"
    
    (status_log, data_log) = build_websocket_response_framework(PolygonLULDStocksWebSocketsEndpointModel)
    @test status_log == DataFrame(
        event_type=String[],
        status=String[],
        message=String[],)

    @test data_log == DataFrame(
        event_type=String[],
        symbol=String[],
        high_price=Float64[],
        low_price=Float64[],
        indicators=Union{Nothing,Vector{Int}}[],
        tape=Int[],
        timestamp=DateTime[],
        sequence=Int[],
    )
end

# ===========================================================================================================
# test Stock

@testset "test error exception for wrong url" begin 
    try
        api(endpoint_model, "et.polygon.io/stocks", status_log, data_log)
    catch err
        @test occursin("ArgumentError: url et.polygon.io/stocks is not properly formatted", string(err))
    end
end



@testset "test api call no concurrent connection" begin
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
    "status, success, subscribed to: LULD.AAPL\n"*
    "status, success, subscribed to: LULD.TSLA\n"*
    "status, success, subscribed to: LULD.MSFT\n"*
    "status, success, subscribed to: LULD.AMZN\n"*
    "status, success, subscribed to: LULD.META\n"*
    "status, success, subscribed to: LULD.AMD\n"*
    "status, success, subscribed to: LULD.GOOG\n"*
    "status, success, subscribed to: LULD.HOOD\n"*
    "status, success, subscribed to: LULD.NFLX\n"*
    "status, success, subscribed to: LULD.NVDA\n"*
    "status, success, subscribed to: LULD.PLTR\n"
    @test output_contents == expected_output_contents
    
end

@testset "test api call with wrong url" begin
    endpoint_model.apikey = "wrong_Key"
    @test endpoint_model.apikey == "wrong_Key" 
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