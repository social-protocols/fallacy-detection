function classify(test_cases::Vector{TestCase}, secret_key::String, model::String)::Vector{ClassificationResult}
    @info "Generating classification..."
    parsed_results = test_cases |>
        (cases) -> map((test_case) -> get_classification(test_case.text, secret_key, model), cases) |>
        (cases) -> map(JSON.parse, cases)
    return map(enumerate(zip(test_cases, parsed_results))) do (i, (case, result))
        gpt_response_to_classification_result(i, case, result)
    end
end

function get_classification(text::String, secret_key::String, model::String)::String
    intro_message = Dict(
        "role" => "system",
        "name" => "evaluator",
        "content" => """
            You will be presented with a piece of content.
            Your task is to detect whether or not there is a rhetorical fallacy in it.
            This is the piece of content:
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
            Please lay out your reasoning why there is or isn't a rhetorical fallacy present, then present your decision.
        """
    )

    r = OpenAI.create_chat(
        secret_key, model,
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
                                        "description" => "Probability of the fallacy being present (between 0.0 and 1.0).",
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

function gpt_response_to_classification_result(id::Int, test_case::TestCase, result::Dict{String, Any})::ClassificationResult
    detected_fallacies = map(result["detected_fallacies"]) do fallacy_dict
        Fallacy(fallacy_dict["name"], fallacy_dict["analysis"], fallacy_dict["probability"])
    end
    return ClassificationResult(id, test_case, detected_fallacies)
end

