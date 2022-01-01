mutable struct PQPolygonSDKUserModel

    # data about the user -
    email::String
    apikey::String

    PQPolygonSDKUserModel() = new()
end

# what is the base type for all endpoint calls?
abstract type AbstractPolygonEndpointModel end
mutable struct PolygonAggregatesEndpointModel <: AbstractPolygonEndpointModel

    # data -
    adjusted::Bool
    limit::Int64
    sortdirection::String
    ticker::String
    to::Date
    from::Date
    multiplier::Int64
    timespan::String
    apikey::String

    # constructor -
    PolygonAggregatesEndpointModel() = new()
end

mutable struct PolygonOptionsContractReferenceEndpoint <: AbstractPolygonEndpointModel

    # data -
    ticker::Union{Nothing,String}
    underlying_ticker::Union{Nothing, String}
    contract_type::String
    expiration_date::Date
    limit::Int64
    order::String
    sort::String
    apikey::String

    # constructor -
    PolygonOptionsContractReferenceEndpoint() = new()
end
