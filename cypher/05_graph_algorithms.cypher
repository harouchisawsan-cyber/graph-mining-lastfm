// =====================================================================
// 05 - Part D2: node similarity with personalized PageRank
//      (random walk with restart of the lecture)
// Graph: in-memory projection 'friends' (User, IS_FRIEND, undirected),
// created in 04_community_detection.cypher. Communities: u.louvain.
// Run the queries ONE BY ONE in Neo4j Query.
// =====================================================================


// ---------------------------------------------------------------------
// 0. Projection (only if Neo4j was restarted; error "already exists" = OK)
// ---------------------------------------------------------------------
CALL gds.graph.project('friends', 'User', {IS_FRIEND: {orientation: 'UNDIRECTED'}})
YIELD graphName, nodeCount, relationshipCount;


// ---------------------------------------------------------------------
// 1. Personalized PageRank from one user: its 10 most similar users
//    sourceNodes = starting point of the walk
//    dampingFactor 0.85 = continue 85% of the time, restart 15%
//    Change the userId to run it from another user.
// ---------------------------------------------------------------------
MATCH (src:User {userId: 1213})
CALL gds.pageRank.stream('friends', {
  sourceNodes: [src],
  dampingFactor: 0.85,
  concurrency: 1
})
YIELD nodeId, score
WITH src, gds.util.asNode(nodeId) AS u, score
WHERE u <> src
RETURN u.userId AS user,
       u.louvain AS community,
       u.louvain = src.louvain AS same_community,
       EXISTS { (src)-[:IS_FRIEND]-(u) } AS is_friend,
       round(score, 4) AS score
ORDER BY score DESC LIMIT 10;

// Results (top 10 most similar users):
// 1213 (Synth-pop, anchored):  8/10 same community, 9/10 friends
//                              not friend but close: 78 (Électro)
// 1543 (Metal hub):            5/10 same community (3 Électro, 2 Synth-pop), 8/10 friends
//                              not friends but close: 1488 (Metal), 78 (Électro)
// 831  (bridge):               4/10 same community (3 Metal, 2 Électro, 1 other), 9/10 friends
//                              not friend but close: 1210 (Synth-pop)


// ---------------------------------------------------------------------
// 2. Use case: music recommendation for user 1213
// 2a. What 1213 already listens to
// Result: De/Vision, Magic Man, e-gens, Electro Spectre, Depeche Mode, Provision...
// ---------------------------------------------------------------------
MATCH (:User {userId: 1213})-[r:LISTEN_TO]->(a:Artist)
RETURN a.name AS artist, r.weight AS listens
ORDER BY listens DESC LIMIT 10;


// 2b. Recommend artists listened to by the 20 most similar users,
//     that 1213 does not listen to yet. Score = sum of the PageRank
//     scores of the similar users who listen to the artist.
// Result: Dave Gahan, Recoil, Madonna, Martin L. Gore, Lady Gaga, Hurts,
//         Placebo, The Cure, Radiohead, U2
MATCH (src:User {userId: 1213})
CALL gds.pageRank.stream('friends', {
  sourceNodes: [src], dampingFactor: 0.85, concurrency: 1
})
YIELD nodeId, score
WITH src, gds.util.asNode(nodeId) AS u, score
WHERE u <> src
ORDER BY score DESC LIMIT 20
MATCH (u)-[:LISTEN_TO]->(a:Artist)
WHERE NOT EXISTS { (src)-[:LISTEN_TO]->(a) }
RETURN a.name AS artist,
       count(u) AS similar_users_listening,
       round(sum(score), 4) AS reco_score
ORDER BY reco_score DESC LIMIT 10;
