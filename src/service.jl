function run_classification(;secret_key::String, database_path::String, model::String, override::Bool)
    if override && isfile(database_path)
        rm(database_path)
        db = get_db(database_path)
    else
        db = get_db(database_path)
    end

    test_cases = get_test_case_data()
    test_cases = test_cases[1:15]

    classification_results = classify(test_cases, secret_key, model)

    insert_test_cases(db, classification_results)
    insert_human_annotated_fallacies(db, classification_results)
    insert_gpt_detected_fallacies(db, classification_results)

    @info "Done classifying fallacies!"
end

