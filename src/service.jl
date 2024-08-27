function run_classification(; secret_key::String, database_path::String, model::String, override::Bool)
    if override && isfile(database_path)
        rm(database_path)
        db = get_db(database_path)
    else
        db = get_db(database_path)
    end

    test_cases = get_test_case_data()
    test_cases = test_cases[1:3]

    classification_results = classify(test_cases, secret_key, model)

    insert_test_cases(db, classification_results)
    insert_human_annotated_fallacies(db, classification_results)
    insert_gpt_detected_fallacies(db, classification_results)

    @info "Done classifying fallacies!"
end

function run_server(; port::Int, host::String, database_path::String, secret_key::String, model::String)
    Genie.Configuration.config!(server_port = port, server_host = host)

    db = get_db(database_path)

    route("/classify", method = POST) do
        message = rawpayload()
        parsed_message = JSON.parse(message)
        test_case = TestCase(parsed_message["post"], ["hasty generalization"])

        result =
            get_classification(parsed_message["post"], secret_key, model) |>
            (res) -> JSON.parse(res) |>
            (res) -> gpt_response_to_classification_result(100, test_case, res)

            @info "result: $result"

            # insert_test_cases(db, [result])
            # insert_gpt_detected_fallacies(db, [result])
    end

    up(async = false)
end
