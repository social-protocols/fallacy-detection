struct TestCase
    text::String
    labels::Vector{String}
end

struct Fallacy
    label::String
    reasoning::String
    probability::Float64
end

struct ClassificationResult
    id::Int
    test_case::TestCase
    gpt_detected_fallacies::Vector{Fallacy}
end

function get_test_case_data()::Vector{TestCase}
    @info "Fetching test case data..."
    r = HTTP.request("GET", "https://raw.githubusercontent.com/ChadiHelwe/MAFALDA/0df434477b914a20f55c0592ba05a53fe924c65b/datasets/gold_standard_dataset.jsonl")
    json_result = String(r.body)
    jsonl = split(json_result, "\n")
    parsed_data = [JSON3.read(line) for line in jsonl if !isempty(line)]
    test_cases = TestCase[]
    for obj in parsed_data
        push!(
            test_cases,
            TestCase(
                obj[:text],
                [l[3] for l in obj[:labels]],
            ),
        )
    end
    return test_cases
end
