# setup internal paths -
_PATH_TO_SRC = dirname(pathof(@__MODULE__))

# load external packages that we depend upon -
using DataFrames
using CSV
using HTTP
using TOML
using Dates
using JSON

# since both WebSockets and HTTP can exports WebSockets, we specifically use HTTP.WebSockets as WSS to 
# eliminate ambiguity. The Websockets from HTTP have higher performance (lower response time) than 
# Websockets from Websockets
import HTTP.WebSockets as WSS

# load my codes -
include(joinpath(_PATH_TO_SRC, "Types.jl"))
include(joinpath(_PATH_TO_SRC, "Base.jl"))
include(joinpath(_PATH_TO_SRC, "Network.jl"))
include(joinpath(_PATH_TO_SRC, "Factory.jl"))
include(joinpath(_PATH_TO_SRC, "Handler.jl"))