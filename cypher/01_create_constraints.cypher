// =====================================================================
// 01 - Constraints (Part A, Q3)
// One node per id + an index so that MERGE is fast.
// Run the queries one by one in Neo4j Query.
// =====================================================================

// Optional: start from an empty database
MATCH (n) DETACH DELETE n;

CREATE CONSTRAINT user_id IF NOT EXISTS FOR (u:User) REQUIRE u.userId IS UNIQUE;
CREATE CONSTRAINT artist_id IF NOT EXISTS FOR (a:Artist) REQUIRE a.artistId IS UNIQUE;

// Temporary: lookup table tagId -> word (deleted at the end of 02_load_data)
CREATE CONSTRAINT tagtmp_id IF NOT EXISTS FOR (t:TagTmp) REQUIRE t.tagId IS UNIQUE;
