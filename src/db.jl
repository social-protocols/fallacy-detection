function create_db(path::String)::SQLite.DB
    db = SQLite.DB(path)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS test_cases (
            id INTEGER PRIMARY KEY AUTOINCREMENT
            , content TEXT NOT NULL
        )
    """)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS human_annotated_fallacies (
            test_case_id INTEGER
            , label TEXT NOT NULL
            , PRIMARY KEY (test_case_id, label)
        )
    """)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS gpt_detected_fallacies (
            test_case_id INTEGER
            , label TEXT NOT NULL
            , reasoning TEXT NOT NULL
            , probability REAL NOT NULL
            , PRIMARY KEY (test_case_id, label)
        )
    """)
    return db
end

function get_db(path::String)::SQLite.DB
    if isfile(path)
        return SQLite.DB(path)
    else
        return create_db(path)
    end
end

function insert_test_cases(db::SQLite.DB, classification_results::Vector{ClassificationResult})::Nothing
    query = """
        INSERT INTO test_cases (id, content)
        VALUES (?, ?)
    """
    cases = map(res -> res.test_case, classification_results)
    for (i, case) in enumerate(cases)
        DBInterface.execute(db, query, (i, case.text))
    end
end

function insert_gpt_detected_fallacies(db::SQLite.DB, classification_results::Vector{ClassificationResult})::Nothing
    query = """
        INSERT INTO gpt_detected_fallacies (test_case_id, label, reasoning, probability)
        VALUES (?, ?, ?, ?)
    """
    for result in classification_results
        for fallacy in result.gpt_detected_fallacies
            DBInterface.execute(db, query, (result.id, fallacy.label, fallacy.reasoning, fallacy.probability))
        end
    end
end

function insert_human_annotated_fallacies(db::SQLite.DB, classification_results::Vector{ClassificationResult})::Nothing
    query = """
        INSERT INTO human_annotated_fallacies (test_case_id, label)
        VALUES (?, ?)
    """
    for result in classification_results
        unique_labels = unique(result.test_case.labels)
        for l in unique_labels
            DBInterface.execute(db, query, (result.id, l))
        end
    end
end
