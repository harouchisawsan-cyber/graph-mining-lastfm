// 1. Créer le graphe en mémoire
CALL gds.graph.project('friends', 'User',
  {IS_FRIEND: {orientation: 'UNDIRECTED'}});

// 2. Lancer les deux méthodes : randomSeed et concurrency: 1 rendent les résultats reproductibles.
CALL gds.louvain.mutate('friends',
  {mutateProperty: 'louvain', randomSeed: 42, concurrency: 1})
YIELD communityCount, modularity;

CALL gds.labelPropagation.mutate('friends',
  {mutateProperty: 'lpa', maxIterations: 20, randomSeed: 42, concurrency: 1})
YIELD communityCount, didConverge;


// 3. Modularité de Label Propagation
CALL gds.modularity.stats('friends', {communityProperty: 'lpa'})
YIELD modularity, communityCount; 

//4. Écrire les communautés dans la base et voir les tailles
CALL gds.graph.nodeProperties.write('friends', ['louvain', 'lpa']);

