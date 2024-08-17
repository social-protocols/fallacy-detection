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

            These are the definitions of the fallacies:

            Formal Definitions
            We begin by defining the variables/placeholders used in the formal templates:

            A = attack
            E = entity (persons, organizations) or group of entities
            P, Pᵢ = premises, properties, or possibilities
            C = conclusion
            The following definitions are inspired by Bennett (2012) and have been adapted to be more generic.

            Abusive Ad Hominem
            E claims P. E’s character is attacked (A). Therefore, ¬P.
            Guilt by Association
            E₁ claims P. Also, E₂ claims P, and E₂’s character is attacked (A). Therefore, ¬P.
            OR E₁ claims P. E₂’s character is attacked (A) and is similar to E₁. Therefore, ¬P.
            Tu quoque
            E claims P, but E is acting as if ¬P. Therefore, ¬P.
            Appeal to Anger
            E claims P. E is outraged. Therefore, P.
            OR E₁ claims P. E₂ is outraged by P. Therefore, P (or ¬P depending on the situation).
            Appeal to Authority
            E claims P (when E is seen as an authority on the facts relevant to P). Therefore, P.
            Ad Populum
            A lot of people believe/do P. Therefore, P.
            OR Only a few people believe/do P. Therefore, ¬P.
            Appeal to Fear
            If ¬P₁, something terrible P₂ will happen. Therefore, P₁.
            Appeal to Nature
            P₁ is natural. P₂ is not natural. Therefore, P₁ is better than P₂.
            OR P₁ is natural, therefore P₁ is good.
            Appeal to Pity
            P which is pitiful, therefore C, with only a superficial link between P and C.
            Appeal to Tradition
            We have been doing P for generations. Therefore, we should keep doing P.
            OR Our ancestors thought P. Therefore, P.
            Causal Oversimplification
            P₁ caused C (although P₂, P₃, P₄, etc. also contributed to C).
            Circular Reasoning
            C because of P. P because of C.
            OR C because C.
            Equivocation
            No logical form: P₁ uses a term T that has a meaning M₁. P₂ uses the term T with the meaning M₂ to mislead.
            False Dilemma
            Either P₁ or P₂, while there are other possibilities.
            OR Either P₁, P₂, or P₃, while there are other possibilities.
            Hasty Generalization
            Sample E₁ is taken from population E. (Sample E₁ is a very small part of population E.) Conclusion C is drawn from sample E₁.
            False Causality
            P is associated with C (when the link is mostly temporal and not logical). Therefore, P causes C.
            Appeal to Worse Problems
            P₁ is presented. P₂ is presented as a best-case. Therefore, P₁ is not that good.
            OR P₁ is presented. P₂ is presented as a worst-case. Therefore, P₁ is very good.
            Slippery Slope
            P₁ implies P₂, then P₂ implies P₃, … then C which is negative. Therefore, ¬P₁.
            Strawman Fallacy
            E₁ claims P. E₂ restates E₁’s claim (in a distorted way P'). E₂ attacks (A) P'. Therefore, ¬P.
            Appeal to Positive Emotion
            P is positive. Therefore, P.
            False Analogy
            E₁ is like E₂. E₂ has property P. Therefore, E₁ has property P. (but E₁ really is not too much like E₂)
            Appeal to Ridicule
            E₁ claims P. E₂ makes P look ridiculous, by misrepresenting P (P'). Therefore, ¬P.
            Fallacy of Division
            E₁ is part of E, E has property P. Therefore, E₁ has property P.
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
        seed = 1337,
        top_p = 0,
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
                                        "description" => "Provide reasoning whether or not a given fallacy is present. Be concise."
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

