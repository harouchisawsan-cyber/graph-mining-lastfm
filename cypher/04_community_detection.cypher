// =====================================================================
// 04 - Communities (Part C, Q8 to Q11) with the GDS library
// Graph studied: friendship network (User, IS_FRIEND), undirected.
// Run the queries ONE BY ONE in Neo4j Query.
// =====================================================================


// ---------------------------------------------------------------------
// 0. In-memory projection of the friendship network
//    (lost when Neo4j stops: run it again at the start of each session)
// ---------------------------------------------------------------------
CALL gds.graph.drop('friends', false) YIELD graphName;

CALL gds.graph.project(
  'friends',
  'User',
  {IS_FRIEND: {orientation: 'UNDIRECTED'}}
)
YIELD graphName, nodeCount, relationshipCount;
// Expected: nodeCount 1892, relationshipCount 25434
// (UNDIRECTED = each friendship stored in both directions inside GDS: 2 x 12717)


// ---------------------------------------------------------------------
// Q8a. Louvain -> property u.louvain
//      concurrency 1 = same result every time we run it
// ---------------------------------------------------------------------
CALL gds.louvain.write('friends', {
  writeProperty: 'louvain',
  concurrency: 1
})
YIELD communityCount, modularity, ranLevels, communityDistribution
RETURN communityCount, round(modularity, 4) AS modularity, ranLevels,
       communityDistribution.max AS biggest, communityDistribution.p50 AS median_size;


// ---------------------------------------------------------------------
// Q8b. Label Propagation -> property u.lpa
//      (modularity of LPA is computed in Python: GDS does not return it here)
// ---------------------------------------------------------------------
CALL gds.labelPropagation.write('friends', {
  writeProperty: 'lpa',
  maxIterations: 20,
  concurrency: 1
})
YIELD communityCount, ranIterations, didConverge, communityDistribution
RETURN communityCount, ranIterations, didConverge,
       communityDistribution.max AS biggest, communityDistribution.p50 AS median_size;


// ---------------------------------------------------------------------
// Q8c. Size distribution: the 10 largest communities of each method
// ---------------------------------------------------------------------
MATCH (u:User)
RETURN u.louvain AS community, count(*) AS size
ORDER BY size DESC LIMIT 10;

MATCH (u:User)
RETURN u.lpa AS community, count(*) AS size
ORDER BY size DESC LIMIT 10;

// How many communities of each size (Louvain)
MATCH (u:User)
WITH u.louvain AS c, count(*) AS size
RETURN size, count(*) AS nb_communities
ORDER BY size DESC;


// ---------------------------------------------------------------------
// Q10 (example in Cypher for ONE community): its most typical artists
// Replace 123 by the id of a big Louvain community (see Q8c).
// lift = share of the community listening to the artist
//        / share of all users listening to it  (>1 = typical of the community)
// ---------------------------------------------------------------------
MATCH (u:User) WITH count(u) AS N
MATCH (u:User {louvain: 123}) WITH N, count(u) AS n_c
MATCH (u:User {louvain: 123})-[:LISTEN_TO]->(a:Artist)
WITH N, n_c, a, count(u) AS in_c
WHERE in_c >= 5
WITH N, n_c, a, in_c, COUNT { (:User)-[:LISTEN_TO]->(a) } AS total
RETURN a.name AS artist, in_c AS listeners_in_community,
       round(100.0 * in_c / n_c, 1) AS pct_community,
       round(100.0 * total / N, 1) AS pct_all_users,
       round((1.0 * in_c / n_c) / (1.0 * total / N), 1) AS lift
ORDER BY lift DESC LIMIT 10;


// ---------------------------------------------------------------------
// Q11 (Cypher view): users whose friends are spread over many communities
// ---------------------------------------------------------------------
MATCH (u:User)-[:IS_FRIEND]-(f:User)
WITH u, count(f) AS friends,
     count(DISTINCT f.louvain) AS communities_among_friends,
     sum(CASE WHEN f.louvain <> u.louvain THEN 1 ELSE 0 END) AS friends_outside
WHERE friends >= 10
RETURN u.userId AS user, u.louvain AS own_community, friends,
       communities_among_friends,
       round(100.0 * friends_outside / friends, 1) AS pct_friends_outside
ORDER BY communities_among_friends DESC, pct_friends_outside DESC LIMIT 10;


// ---------------------------------------------------------------------
// End: free the memory
// ---------------------------------------------------------------------
// CALL gds.graph.drop('friends') YIELD graphName;
