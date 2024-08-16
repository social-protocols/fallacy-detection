# TODO: probably don't need two JSON libraries
using JSON
using JSON3
using OpenAI

OPENAI_API_KEY = ENV["OPENAI_API_KEY"]
LLM = "gpt-4o-mini"

# Function to read a JSONL file and return an array of parsed JSON objects
function read_jsonl(file_path::String)
    json_objects = []

    open(file_path, "r") do file
        for line in eachline(file)
            push!(json_objects, JSON3.read(line))
        end
    end

    return json_objects
end

# Example usage
file_path = "gold_standard_dataset.jsonl"
json_objects = read_jsonl(file_path)

struct TestDataPoint
    text::String
    labels::Vector{String}
end

function find_first_string(arr)
    index = findfirst(x -> isa(x, String), arr)
    return index !== nothing ? arr[index] : nothing
end

data = TestDataPoint[]

for obj in json_objects
    push!(
        data,
        TestDataPoint(
            obj[:text],
            [l[3] for l in obj[:labels]],
        ),
    )
end

# fallacies = unique(reduce(vcat, [d.labels for d in data]))

# write JSON data
# map(JSON3.write, data)

function get_classification(text::String)::String

    intro_message = Dict(
        "role" => "system",
        "name" => "evaluator",
        "content" => """
            Following is a post from a social media platform.
            Your task is to detect whether or not there is a slippery slope fallacy in it.
        """
    )

    test_message = Dict(
        "role" => "user",
        "name" => "socialmediauser",
        "content" => text,
    )

    task_message = Dict(
        "role" => "system",
        "name" => "evaluator",
        "content" => """
            Please lay out your reasoning why there is or isn't a slippery slope fallacy present, then present your decision.
        """
    )

    r = OpenAI.create_chat(
        OPENAI_API_KEY, LLM,
        [intro_message; test_message; task_message];
        response_format = Dict(
            "type" => "json_schema",
            "json_schema" => Dict(
                "name" => "fallacy_detection",
                "strict" => true,
                "schema" => Dict(
                    "type" => "object",
                    "additionalProperties" => false,
                    "properties" => Dict(
                        "detected_fallacies" => Dict(
                            "type" => "array",
                            "items" => Dict(
                                "type" => "object",
                                "additionalProperties" => false,
                                "properties" => Dict(
                                    "name" => Dict(
                                        "type" => "string",
                                        "enum" => [
                                            "slippery slope",
                                            "hasty generalization",
                                            "false analogy",
                                            "guilt by association",
                                            "causal oversimplification",
                                            "ad populum",
                                            "nothing",
                                            "circular reasoning",
                                            "appeal to fear",
                                            "ad hominem",
                                            "appeal to (false) authority",
                                            "false causality",
                                            "fallacy of division",
                                            "Appeal to Ridicule",
                                            "appeal to worse problems",
                                            "appeal to nature",
                                            "false dilemma",
                                            "straw man",
                                            "appeal to anger",
                                            "appeal to positive emotion",
                                            "equivocation",
                                            "to clean",
                                            "appeal to tradition",
                                            "appeal to pity",
                                            "tu quoque",
                                        ],
                                    ),
                                    "analysis" => Dict(
                                        "type" => "string",
                                        "description" => "Provide reasoning whether or not a given fallacy is present."
                                    ),
                                    "probability" => Dict(
                                        "type" => "number",
                                        "description" => "Probability of the fallacy being present."
                                    )
                                ),
                                "required" => ["name", "analysis", "probability"]
                            )
                        )
                    ),
                    "required" => ["detected_fallacies"],
                ),
            )
        )
    )

    return r.response[:choices][begin][:message][:content]
end

texts_only = [d.text for d in data]

results = map(get_classification, texts_only)

parsed_results = map(JSON.parse, results)

final_results = Dict{String, Any}[]

for (i, res) in enumerate(parsed_results)
    dict = parsed_results[i]
    dict["text"] = data[i].text
    dict["true_labels"] = data[i].labels
    push!(final_results, dict)
end

jsonl_results = map(JSON3.write, final_results)

open("results.jsonl", "w") do file
    for res in jsonl_results
        write(file, res * "\n")
    end
end
