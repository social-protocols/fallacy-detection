using JSON3
using SQLite

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
        error("No database exists at path $path.")
    end
end

function insert_test_cases(db::SQLite.DB, cases::Vector{String})
    query = """
        INSERT INTO test_cases (id, content)
        VALUES (?, ?)
    """
    for (i, case) in enumerate(cases)
        DBInterface.execute(db, query, (i, case))
    end
end

function insert_fallacies(db::SQLite.DB, fallacies::Vector{Vector})
    query = """
        INSERT INTO gpt_detected_fallacies (test_case_id, label, reasoning, probability)
        VALUES (?, ?, ?, ?)
    """
    for (i, detection) in enumerate(fallacies)
        for flc in detection
            DBInterface.execute(db, query, (i, flc[:name], flc[:analysis], flc[:probability]))
        end
    end
end

function insert_true_labels(db::SQLite.DB, labels::Vector{Vector})
    query = """
        INSERT INTO human_annotated_fallacies (test_case_id, label)
        VALUES (?, ?)
    """
    for (i, label) in enumerate(labels)
        for l in label
            DBInterface.execute(db, query, (i, l))
        end
    end
end

rm("fallacy-detection.db")

results = []
open("results.jsonl") do file
    global results = [JSON3.read(line) for line in eachline(file)]
end

db = create_db("fallacy-detection.db")

contents = [res["text"] for res in results]
insert_test_cases(db, contents)

true_labels = [unique(vcat(res[:true_labels])) for res in results]
insert_true_labels(db, true_labels)

fallacies = [[Dict(fallacy) for fallacy in res["detected_fallacies"]] for res in results]
insert_fallacies(db, fallacies)
