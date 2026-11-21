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

// Artistes écoutés par utilisateur (degré sortant) : moyenne et max
MATCH (u:User)
WITH COUNT { (u)-[:LISTEN_TO]->() } AS deg
RETURN avg(deg) AS moyenne, max(deg) AS maximum;