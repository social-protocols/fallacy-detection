module FallacyDetection

using JSON
using JSON3
using SQLite
using OpenAI
using HTTP
using Genie, Genie.Renderer.Json, Genie.Requests

OPENAI_API_KEY = ENV["OPENAI_API_KEY"]
LLM = "gpt-4o-mini"

include("utils.jl")
include("db.jl")
include("classification.jl")
include("service.jl")

export run_classification
export run_server

end
