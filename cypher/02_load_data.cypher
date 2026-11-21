// =====================================================================
// 02 - Load the Last.fm (HetRec 2011) data (Part A, Q3)
//
// Before: run 01_create_constraints.cypher and src/clean_text_files.py,
// then copy into the Neo4j "import" folder: artists_clean.tsv,
// tags_clean.tsv, user_artists.dat, user_friends.dat, user_taggedartists.dat
//
// Run the queries ONE BY ONE. "Result:" = what we obtained.
// =====================================================================


// ---------------------------------------------------------------------
// 1. Checks on the raw files (nothing is created)
// ---------------------------------------------------------------------

// 1a. Friendships: lines, self-loops, symmetry
// Result: 25434 lines, 12717 with a<b, 0 self-loops, 12717 distinct pairs
LOAD CSV WITH HEADERS FROM 'file:///user_friends.dat' AS row FIELDTERMINATOR '\t'
WITH toInteger(row.userID) AS a, toInteger(row.friendID) AS b
RETURN count(*) AS lines,
       sum(CASE WHEN a < b THEN 1 ELSE 0 END) AS lines_a_lt_b,
       sum(CASE WHEN a = b THEN 1 ELSE 0 END) AS self_loops,
       count(DISTINCT CASE WHEN a < b THEN [a, b] ELSE [b, a] END) AS distinct_pairs;

// 1b. Listening: duplicates?
// Result: 92834 lines = 92834 distinct pairs -> no duplicate
LOAD CSV WITH HEADERS FROM 'file:///user_artists.dat' AS row FIELDTERMINATOR '\t'
RETURN count(*) AS lines, count(DISTINCT [row.userID, row.artistID]) AS distinct_pairs;

// 1c. Tag assignments: duplicates?
// Result: 186479 lines = 186479 distinct triples -> no duplicate
LOAD CSV WITH HEADERS FROM 'file:///user_taggedartists.dat' AS row FIELDTERMINATOR '\t'
RETURN count(*) AS lines, count(DISTINCT [row.userID, row.artistID, row.tagID]) AS distinct_triples;


// ---------------------------------------------------------------------
// 2. Artist nodes
// Result: 17632 nodes
// ---------------------------------------------------------------------
LOAD CSV WITH HEADERS FROM 'file:///artists_clean.tsv' AS row FIELDTERMINATOR '\t'
MERGE (a:Artist {artistId: toInteger(row.id)})
SET a.name = row.name, a.url = row.url;


// ---------------------------------------------------------------------
// 3. User nodes + LISTEN_TO (weight = listening count)
// Result: 1892 nodes (users only), 92834 relationships
// ---------------------------------------------------------------------
LOAD CSV WITH HEADERS FROM 'file:///user_artists.dat' AS row FIELDTERMINATOR '\t'
MERGE (u:User {userId: toInteger(row.userID)})
MERGE (a:Artist {artistId: toInteger(row.artistID)})
MERGE (u)-[r:LISTEN_TO]->(a)
SET r.weight = toInteger(row.weight);


// ---------------------------------------------------------------------
// 4. IS_FRIEND: one relationship per pair
//    MERGE without arrow: (275,2) does not create a 2nd edge after (2,275)
// Result: 0 nodes, 12717 relationships
// ---------------------------------------------------------------------
LOAD CSV WITH HEADERS FROM 'file:///user_friends.dat' AS row FIELDTERMINATOR '\t'
WITH toInteger(row.userID) AS a, toInteger(row.friendID) AS b
WHERE a <> b
MERGE (u:User {userId: a})
MERGE (v:User {userId: b})
MERGE (u)-[:IS_FRIEND]-(v);


// ---------------------------------------------------------------------
// 5. TAGGED (with the tag word)
// ---------------------------------------------------------------------

// 5a. Temporary lookup table tagId -> word
// Result: 11946 nodes
LOAD CSV WITH HEADERS FROM 'file:///tags_clean.tsv' AS row FIELDTERMINATOR '\t'
MERGE (t:TagTmp {tagId: toInteger(row.tagID)})
SET t.name = row.tagValue;

// 5b. How many tag rows point to an artist missing from artists.dat?
// Result: 1538 of 186479 (0.8%)
LOAD CSV WITH HEADERS FROM 'file:///user_taggedartists.dat' AS row FIELDTERMINATOR '\t'
OPTIONAL MATCH (a:Artist {artistId: toInteger(row.artistID)})
RETURN count(*) AS lines, sum(CASE WHEN a IS NULL THEN 1 ELSE 0 END) AS unknown_artist;

// 5c. TAGGED relationships (MATCH on Artist: no nameless artist is created)
// Result: 0 nodes, 184941 relationships
LOAD CSV WITH HEADERS FROM 'file:///user_taggedartists.dat' AS row FIELDTERMINATOR '\t'
MATCH (a:Artist {artistId: toInteger(row.artistID)})
MATCH (t:TagTmp {tagId: toInteger(row.tagID)})
MERGE (u:User {userId: toInteger(row.userID)})
MERGE (u)-[r:TAGGED {tagId: t.tagId}]->(a)
SET r.tag = t.name, r.day = toInteger(row.day),
    r.month = toInteger(row.month), r.year = toInteger(row.year);

// 5d. Remove the temporary table
MATCH (t:TagTmp) DETACH DELETE t;
DROP CONSTRAINT tagtmp_id IF EXISTS;


// ---------------------------------------------------------------------
// 6. Final checks
// ---------------------------------------------------------------------

// Nodes per label. Result: Artist 17632, User 1892
MATCH (n) RETURN labels(n)[0] AS label, count(*) AS nb ORDER BY label;

// Relationships per type. Result: IS_FRIEND 12717, LISTEN_TO 92834, TAGGED 184941
MATCH ()-[r]->() RETURN type(r) AS type, count(*) AS nb ORDER BY type;

// Duplicate edges. Result: no records -> 0 duplicates
MATCH (u:User)-[r:LISTEN_TO]->(a:Artist)
WITH u, a, count(r) AS c WHERE c > 1
RETURN 'LISTEN_TO' AS type, count(*) AS duplicated_pairs
UNION ALL
MATCH (u:User)-[r:IS_FRIEND]-(v:User) WHERE u.userId < v.userId
WITH u, v, count(r) AS c WHERE c > 1
RETURN 'IS_FRIEND' AS type, count(*) AS duplicated_pairs
UNION ALL
MATCH (u:User)-[r:TAGGED]->(a:Artist)
WITH u, a, r.tagId AS tag, count(r) AS c WHERE c > 1
RETURN 'TAGGED' AS type, count(*) AS duplicated_pairs;

// Self-loops. Result: no records -> 0
MATCH (n)-[r]->(n) RETURN type(r) AS type, count(*) AS self_loops;

// Isolated nodes. Result: no records -> 0
MATCH (n) WHERE NOT EXISTS { (n)--() } RETURN labels(n)[0] AS label, count(*) AS isolated;

// Users without friends (isolated in the friendship network). Result: 0
MATCH (u:User) WHERE NOT EXISTS { (u)-[:IS_FRIEND]-() } RETURN count(u) AS users_without_friend;

// Artists without a name. Result: 0
MATCH (a:Artist) WHERE a.name IS NULL RETURN count(a) AS artists_without_name;

// Artists nobody listens to. Result: 0
MATCH (a:Artist) WHERE NOT EXISTS { ()-[:LISTEN_TO]->(a) } RETURN count(a) AS never_listened;
