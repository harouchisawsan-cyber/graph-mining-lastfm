// Amis : moyenne, max, médiane
MATCH (u:User)
WITH COUNT { (u)-[:IS_FRIEND]-() } AS deg
RETURN avg(deg) AS moyenne, max(deg) AS maximum, percentileCont(deg, 0.5) AS mediane;

// Top 10 utilisateurs par nombre d'amis
MATCH (u:User)
RETURN u.userId AS user, COUNT { (u)-[:IS_FRIEND]-() } AS amis
ORDER BY amis DESC LIMIT 10;

// Top 10 artistes par nombre d'auditeurs (degré entrant)
MATCH (a:Artist)
RETURN a.name AS artiste, COUNT { ()-[:LISTEN_TO]->(a) } AS auditeurs
ORDER BY auditeurs DESC LIMIT 10;

// Artistes écoutés par utilisateur (degré sortant) : moyenne, max, médiane
MATCH (u:User)
WITH COUNT { (u)-[:LISTEN_TO]->() } AS deg
RETURN avg(deg) AS moyenne, max(deg) AS maximum, percentileCont(deg, 0.5) AS mediane;

// Auditeurs par artiste : moyenne, max, médiane
MATCH (a:Artist)
WITH COUNT { ()-[:LISTEN_TO]->(a) } AS deg
RETURN avg(deg) AS moyenne, max(deg) AS maximum, percentileCont(deg, 0.5) AS mediane;

// Artistes écoutés par une seule personne
MATCH (a:Artist)
WITH COUNT { ()-[:LISTEN_TO]->(a) } AS d
RETURN sum(CASE WHEN d = 1 THEN 1 ELSE 0 END) AS un_seul, count(*) AS total;


//question 6 : verifiaion du nombre de triangles dans le graphe d'amis
MATCH (a:User)-[:IS_FRIEND]-(b:User)-[:IS_FRIEND]-(c:User)-[:IS_FRIEND]-(a)
WHERE a.userId < b.userId AND b.userId < c.userId
RETURN count(*) AS triangles;