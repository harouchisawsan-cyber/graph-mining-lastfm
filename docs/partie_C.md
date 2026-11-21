# Partie C : Communautés (LastFM)

Réseau étudié : le réseau d'amitié (1 892 utilisateurs, 12 717 amitiés `IS_FRIEND`, non orienté).
Code : `cypher/04_community_detection.cypher` (GDS) et `notebooks/03_communities_analysis.ipynb` (Python).

---

## Q8. Louvain et Label Propagation

Le graphe est projeté en mémoire avec GDS (`gds.graph.project`, orientation `UNDIRECTED`) : 1 892 nœuds et 25 434 relations, car GDS stocke chaque amitié dans les deux sens (2 × 12 717). Les deux algorithmes sont lancés avec `concurrency: 1` pour obtenir un résultat reproductible.

### Tableau 1 : résultats

| | Louvain | Label Propagation |
|---|---|---|
| Nombre de communautés | 30 | 32 |
| dont petites composantes isolées (Q5) | 19 | 19 |
| Plus grande communauté | 565 (29,9 %) | 1 785 (94,3 %) |
| 5 plus grandes | 565, 374, 344, 257, 235 | 1 785, 11, 7, 7, 6 |
| Taille médiane | 3 | 3 |
| Modularité | **0,4542** | **0,0225** |
| Convergence | 3 niveaux | 8 itérations (`didConverge` = true) |

La modularité de Louvain est donnée par GDS et vérifiée en Python (networkx) : même valeur, 0,4542. Celle de Label Propagation est calculée en Python, car GDS ne la renvoie pas pour cet algorithme.

### Interprétation

- **Louvain trouve une structure claire.** Sa modularité (0,45) est dans l'intervalle 0,3–0,7 qui, d'après le cours, indique une structure de communautés claire. Il découpe le réseau en 5 grandes communautés (235 à 565 utilisateurs), qui regroupent 1 775 utilisateurs, soit 94 % du réseau.
- **Label Propagation ne découpe presque pas le réseau.** Il met 94 % des utilisateurs dans une seule communauté. Sa modularité est presque nulle (0,02) : ce découpage ne révèle presque aucune structure.
- **Les petites communautés sont les mêmes.** Dans les deux cas, 19 communautés correspondent aux petites composantes isolées vues en Q5 : un algorithme ne peut pas regrouper des utilisateurs qui ne sont pas reliés.

### Limite

Louvain dépend de l'ordre de calcul : sans `concurrency: 1`, deux exécutions peuvent donner des communautés légèrement différentes.

---

## Q9. Comparaison des deux méthodes

### Tableau 2 : où vont les 5 communautés Louvain dans Label Propagation

| Communauté Louvain | Taille | % dans la communauté géante LPA (17642) | Nombre de communautés LPA |
|---|---|---|---|
| 1357 | 565 | 96,5 % | 5 |
| 373 | 374 | 100 % | 1 |
| 689 | 344 | 100 % | 1 |
| 74 | 257 | 96,1 % | 4 |
| 1061 | 235 | 100 % | 1 |

Scores de ressemblance entre les deux découpages : **ARI = 0,037**, **NMI = 0,266** (1 = découpages identiques, 0 = sans rapport).

### Trouvent-elles les mêmes communautés principales ?

**Non.** Les 5 grandes communautés de Louvain se retrouvent à 96–100 % dans la seule communauté géante de Label Propagation : LPA les a fusionnées. Les deux méthodes ne sont d'accord que sur les petits groupes (les composantes isolées, et quelques petits cercles en bordure, par exemple Louvain 995 = LPA 17826, 11 utilisateurs).

- L'**ARI est presque nul** : pour presque toutes les paires d'utilisateurs de deux grandes communautés différentes, Louvain les sépare et LPA les met ensemble.
- La **NMI est un peu plus haute** grâce aux petites communautés, identiques dans les deux méthodes.

### Pourquoi peuvent-elles être différentes ?

1. **Elles ne cherchent pas la même chose.** Louvain optimise la modularité : il cherche où couper le réseau. Label Propagation n'optimise aucun score : chaque utilisateur prend l'étiquette la plus fréquente chez ses amis.
2. **Notre réseau favorise l'invasion d'une étiquette.** C'est un petit monde (Q5 : 3,5 étapes en moyenne) avec des hubs très connectés (Q4) qui font le pont entre les cercles (Q7). Une étiquette qui atteint ces hubs se répand dans tous les cercles et finit par devenir majoritaire presque partout.
3. **Label Propagation dépend de l'ordre de calcul**, ce qui rend ses résultats instables.

**On garde Louvain** pour la suite : modularité bien plus élevée et communautés de taille exploitable.

### Limite

Il n'existe pas de vérité terrain sur les groupes d'amis : une modularité élevée ne prouve pas que les communautés ont un sens. La Q10 le vérifie avec les artistes et les tags.

---

## Q10. Description des 5 plus grandes communautés

Les utilisateurs sont anonymes : on décrit chaque communauté par ce que ses membres écoutent (`LISTEN_TO`) et par les tags qu'ils utilisent (`TAGGED`). Les artistes les plus écoutés (Lady Gaga, Britney Spears…) sont les mêmes partout ; on utilise donc le **lift** pour trouver ce qui est propre à chaque communauté :

> lift = (% des membres de la communauté qui écoutent l'artiste) / (% de tous les utilisateurs qui l'écoutent)

Un lift de 7 veut dire que l'artiste est 7 fois plus écouté dans la communauté qu'en moyenne. On ne garde que les artistes et les tags utilisés par au moins 10 % des membres de la communauté.

### Tableau 3 : les 5 communautés

| Communauté | Taille | Nom proposé | Artistes typiques (lift) | Tags typiques (lift) |
|---|---|---|---|---|
| 1357 | 565 | **Metal & hardcore** | Escape The Fate, Megadeth (2,8), Bullet for My Valentine, Judas Priest, Slayer, A Day to Remember (2,6) | post-hardcore, metalcore, heavy metal, thrash metal (2,4), death metal (2,2) |
| 373 | 374 | **Pop teen & R&B** | Hannah Montana (4,1), Vanessa Hudgens, Sugababes (3,6), JoJo, Nicki Minaj (3,5), Ciara, Carrie Underwood, Fergie (3,3) | legend (3,7), diva (2,9), amazing, rnb (2,4), sexy (2,2) |
| 689 | 344 | **Électro expérimentale & ambient** | Boards of Canada (3,8), Aphex Twin (3,4), Massive Attack (2,1), Sigur Rós (1,9) | idm (3,4), downtempo (2,9), chillout, ambient (2,2), instrumental, trip-hop, experimental (2,1) |
| 74 | 257 | **Synth-pop & new wave 80s** | De/Vision, Camouflage, Yazoo (7,1), Martin L. Gore (7,0), Ultravox, Dave Gahan (6,9), Simple Minds (6,7), The Human League (6,5) | new romantic (6,4), synth pop (5,7), ebm, synthpop (3,9), darkwave (3,8), new wave (3,7), post-punk (2,9), 80s (2,6) |
| 1061 | 235 | **Pop latine & pop grand public** | Anahí (4,2), RBD (4,1), Jessie J, Pitty (3,9), Belinda (3,5), Duffy (3,4) | diva (2,6), electropop (2,2), rnb (2,0), pop, dance, pop rock (1,8) |

### Interprétation

- **Chaque grand groupe d'amis a un goût musical propre.** Louvain n'a utilisé que les amitiés, et pourtant chaque communauté correspond à un genre cohérent, confirmé à la fois par les artistes et par les tags. Exemple : dans la communauté 74, Martin L. Gore (compositeur de Depeche Mode) est écouté par 15,6 % des membres contre 2,2 % de tous les utilisateurs (lift ≈ 7), et les tags dominants sont « new wave », « synth pop », « new romantic » et « 80s ».
- **Certains groupes sont plus marqués que d'autres.** La communauté synth-pop (lifts de 6 à 7) est une niche très soudée. La communauté metal (lifts de 2,4 à 2,8) est plus grande et mélange plusieurs styles (heavy metal, thrash, metalcore, post-hardcore).
- **Ce sont des tendances, pas des groupes purs.** Même l'artiste le plus typique n'est écouté que par 10 à 27 % des membres (par exemple Iron Maiden par 22 % de la communauté metal).
- **Deux publics pop distincts.** La communauté 373 est tournée vers la pop adolescente et le R&B américains ; la communauté 1061 contient beaucoup d'artistes d'Amérique latine (Anahí, RBD, Belinda, Pitty). Cette séparation vient peut-être du pays ou de la langue des utilisateurs, ce que le dataset ne permet pas de vérifier.

### Vérité terrain

Il n'y en a pas : le dataset n'indique pas de groupe pour chaque utilisateur. Les tags servent de vérité de remplacement (ils décrivent le genre choisi par les utilisateurs eux-mêmes, et Louvain ne les a jamais vus). La correspondance est bonne mais pas parfaite : chaque communauté a des tags dominants cohérents (lift de 2 à 6), mais aucun tag n'est utilisé par plus de 40 % des membres, sauf « pop » (55 %) dans la communauté 1061.

### Limites

- Les tags sont une approximation, posée par une partie seulement des utilisateurs.
- Le classement dépend du seuil de 10 % ; le genre de chaque communauté, lui, ne change pas.
- Corrélation n'est pas causalité : on ne sait pas si les gens deviennent amis parce qu'ils aiment la même musique, ou l'inverse. Un facteur caché (comme le pays) peut expliquer les deux.

---

## Q11. Utilisateurs entre les communautés

Pour chaque utilisateur, on mesure :
- le **% d'amis hors de sa communauté** ;
- le **coefficient de participation** = 1 − Σ (part des amis dans chaque communauté)² : 0 si tous ses amis sont dans une seule communauté, plus élevé si ses amis sont répartis dans plusieurs communautés.

### Tableau 4 : top 10 betweenness (les ponts de la Q7)

| Utilisateur | Communauté | Amis | Betweenness | % amis hors communauté | Participation | Répartition des amis |
|---|---|---|---|---|---|---|
| 1543 | Metal | 119 | 0,0665 | 43,7 | 0,624 | Metal 56 %, Électro 21 %, Synth-pop 9 % |
| 1281 | Metal | 110 | 0,0545 | 36,4 | 0,553 | Metal 64 %, Électro 15 %, Synth-pop 10 % |
| 831 | Synth-pop | 106 | 0,0487 | 74,5 | 0,803 | Synth-pop 25 %, Pop teen 24 %, Électro 18 % |
| 1258 | Synth-pop | 86 | 0,0430 | 50,0 | 0,634 | Synth-pop 50 %, Metal 29 %, Électro 17 % |
| 78 | Électro | 81 | 0,0293 | 33,3 | 0,508 | Électro 67 %, Synth-pop 19 %, Metal 11 % |
| 1213 | Synth-pop | 68 | 0,0242 | 27,9 | 0,452 | Synth-pop 72 %, Électro 13 %, Pop teen 9 % |
| 1130 | Metal | 57 | 0,0238 | 52,6 | 0,696 | Metal 47 %, Pop teen 21 %, Synth-pop 16 % |
| 1503 | Pop teen | 95 | 0,0232 | 43,2 | 0,628 | Pop teen 57 %, Metal 14 %, Pop latine 13 % |
| 298 | Metal | 79 | 0,0231 | 30,4 | 0,481 | Metal 70 %, Pop latine 16 %, Pop teen 8 % |
| 1597 | Metal | 70 | 0,0218 | 37,1 | 0,556 | Metal 63 %, Pop latine 20 %, Pop teen 7 % |

**Participation moyenne : top 10 betweenness = 0,593, tout le réseau = 0,304.**

Parmi les utilisateurs ayant au moins 10 amis, ceux dont les amis sont les plus dispersés sont : 831 (0,803), 1004 (0,800), 655 (0,782), 759 (0,777), 143 (0,775). Vue Cypher : 1706, 759 et 1389 ont plus de 75 % de leurs amis hors de leur communauté.

### Qui sont-ils ?

- **Les ponts de la Q7 sont bien entre les communautés** : leurs amis sont deux fois plus répartis entre les groupes que ceux de l'utilisateur moyen (0,59 contre 0,30).
- **L'utilisateur 831 est le pont parfait** : 106 amis, 3ᵉ en betweenness, 74,5 % de ses amis hors de sa communauté, répartis presque également entre synth-pop, pop teen et électro.
- **1543 et 1281 sont des hubs de la communauté Metal** qui ont aussi beaucoup d'amis chez les fans d'électro.
- **Certains utilisateurs sont entre les communautés sans être des ponts** : 1004 (10 amis, 70 % hors communauté) a une betweenness de 0,0012. Être entre deux groupes ne suffit pas, il faut aussi assez de liens.
- Les liens entre genres les plus visibles : Metal ↔ Électro (1543, 1281, 78), Synth-pop ↔ Pop teen ↔ Électro (831), Metal ↔ Pop latine (298, 1597).

### Pourquoi sont-ils importants ?

1. Ils **relient des goûts différents** : sans eux, les communautés seraient plus isolées.
2. Ils **font circuler la musique entre les genres** : ce sont des cibles naturelles pour des recommandations qui sortent d'un seul genre.
3. Ils **expliquent le résultat de Label Propagation** (Q9) : c'est par ces utilisateurs très connectés qu'une étiquette passe d'une communauté à l'autre.

### Limites

- Les résultats dépendent du découpage de Louvain.
- La participation est peu fiable pour les utilisateurs avec peu d'amis (d'où le seuil de 10 amis).
- Les utilisateurs sont anonymes : on ne sait pas pourquoi ils ont des amis dans plusieurs groupes.
