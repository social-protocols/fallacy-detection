include("src/FallacyDetection.jl")
using Main.FallacyDetection

secret_key = ENV["OPENAI_API_KEY"]
model = "gpt-4o-mini"
database_path = ENV["DATABASE_PATH"]

run_classification(secret_key = secret_key, database_path = database_path, model = model, override = true)
