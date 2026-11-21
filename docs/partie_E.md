# Partie E : Conclusions (Q12)

Chaque conclusion suit le même format : la question, la preuve (un chiffre, un graphique ou une communauté), la réponse et une limite.

---

## Réponse à la question principale (Q1)

**Question.** En utilisant seulement le graphe d'amitié, peut-on retrouver des groupes d'utilisateurs de Last.fm qui ont les mêmes goûts musicaux ?

**Preuves.**
- **Le réseau d'amitié a une structure de groupes** : 49 fois plus de triangles qu'un graphe aléatoire de même taille (19 690 contre 404,9, Q6) et une modularité de Louvain de 0,45 (Q8), dans l'intervalle 0,3–0,7 qui indique une structure claire d'après le cours.
- **Chaque grande communauté a un genre musical propre** (Q10). Louvain n'a utilisé que les amitiés, et pourtant les 5 plus grandes communautés (94 % des utilisateurs) correspondent à 5 genres, confirmés à la fois par les artistes et par les tags, que Louvain n'a jamais vus :

  | Communauté | Taille | Genre | Exemple de preuve |
  |---|---|---|---|
  | 1357 | 565 | Metal & hardcore | Megadeth (lift 2,8), tag « metalcore » (2,4) |
  | 373 | 374 | Pop teen & R&B | Hannah Montana (4,1), tag « diva » (2,9) |
  | 689 | 344 | Électro expérimentale | Boards of Canada (3,8), tag « idm » (3,4) |
  | 74 | 257 | Synth-pop 80s | Martin L. Gore (7,0), tag « new romantic » (6,4) |
  | 1061 | 235 | Pop latine | Anahí (4,2), RBD (4,1) |

- **Les voisins les plus proches d'un utilisateur sont dans sa communauté** (D2) : pour l'utilisateur 1213, 8 de ses 10 voisins les plus proches (PageRank personnalisé) sont dans sa communauté Synth-pop.
- **La recommandation par les amis fonctionne** (D2) : pour 1213, fan de Depeche Mode, les trois premières recommandations de niche sont les projets solo de trois membres de Depeche Mode (Dave Gahan, Martin L. Gore, Recoil).

**Réponse.** **Oui, en grande partie.** Les groupes d'amis trouvés par Louvain correspondent à des genres musicaux. Mais ce sont des **tendances, pas des groupes purs** : même l'artiste le plus typique d'une communauté n'est écouté que par 10 à 27 % de ses membres. Le lien est plus fort pour les **niches** (synth-pop, lifts de 6 à 7) que pour les genres larges (metal, lifts de 2,4 à 2,8).

**Limites.**
- **Corrélation n'est pas causalité** : on ne sait pas si les gens deviennent amis parce qu'ils aiment la même musique, ou s'ils finissent par aimer la même musique parce qu'ils sont amis. Un facteur caché comme le pays peut expliquer les deux (par exemple la communauté Pop latine).
- **Pas de vraie vérité terrain** : les tags servent de remplacement et sont posés par une partie seulement des utilisateurs.
- **Échantillon particulier** : les 1 892 utilisateurs ont tous au moins un ami ; les conclusions valent pour ce groupe, pas forcément pour tout Last.fm.

---

## Conclusion 2 : la popularité des artistes est extrêmement inégale

**Question.** Les écoutes sont-elles réparties entre beaucoup d'artistes, ou concentrées sur quelques stars ?

**Preuve.** Q4 : la médiane est de **1 auditeur par artiste** pour une moyenne de 5,27 ; **10 679 artistes sur 17 632 (60,6 %)** ne sont écoutés que par une seule personne, alors que Lady Gaga en a **611** (environ 116 fois la moyenne). Sur le graphique log-log (`results/figures/degree_distribution.png`), la distribution suit presque une droite : c'est une longue traîne.

**Réponse.** Les écoutes sont très **concentrées** : quelques artistes pop très grand public (Lady Gaga, Britney Spears, Rihanna) sont écoutés partout, et la majorité des artistes sont des niches. C'est pour ça qu'il a fallu utiliser le **lift** en Q10 : sans lui, toutes les communautés auraient les mêmes artistes en tête. Cela se voit aussi en D2, où Madonna et Lady Gaga remontent dans les recommandations par simple popularité.

**Limite.** Le dataset ne garde que les **50 artistes les plus écoutés** par chaque utilisateur (médiane et maximum de 50, Q4) : les artistes de niche écoutés rarement sont sous-représentés.

---

## Conclusion 3 : un petit monde fait de cercles d'amis soudés

**Question.** Le réseau d'amitié ressemble-t-il à un réseau aléatoire ?

**Preuve.**
- Q5 : **97,4 %** des utilisateurs sont dans une seule composante, et deux utilisateurs sont séparés en moyenne par **3,5 amitiés** (diamètre 9).
- Q6 : **19 690 triangles**, contre **404,9** attendus dans un graphe aléatoire de même taille (environ 49 fois plus) ; clustering moyen de **0,187**, contre 0,007 au hasard.

**Réponse.** **Non.** C'est un réseau **petit monde** : des cercles d'amis très soudés (beaucoup de triangles), reliés entre eux par des chemins courts. Cette structure en cercles est exactement ce qui permet à Louvain de trouver des communautés en partie C.

**Limite.** Le graphe aléatoire de référence suppose que tous les utilisateurs ont à peu près le même nombre d'amis, ce qui est faux (Q4). Un modèle qui garde la vraie distribution des degrés donnerait une référence plus juste.

---

## Conclusion 4 : quelques ponts relient les genres, et ils changent le résultat des algorithmes

**Question.** Comment les communautés de goûts sont-elles reliées entre elles, et est-ce que ça influence les algorithmes ?

**Preuve.**
- Q7 et Q11 : les 10 utilisateurs avec la plus forte betweenness ont des amis **deux fois plus répartis** entre les communautés que la moyenne (participation de **0,59** contre **0,30**). Exemple : l'utilisateur 831, 106 amis, dont **74,5 %** hors de sa communauté, répartis entre synth-pop, pop teen et électro.
- Q8 et Q9 : Label Propagation met **94 %** des utilisateurs dans une seule communauté (modularité **0,02**), alors que Louvain en trouve 5 (modularité **0,45**) ; ARI = **0,04** entre les deux découpages.

**Réponse.** Les communautés de goûts sont reliées par **quelques utilisateurs très connectés** (831, 1543, 1281), qui ont des amis dans plusieurs genres. Ces ponts font circuler la musique d'un genre à l'autre. Ce sont aussi eux qui expliquent l'échec de Label Propagation : une étiquette qui les atteint se répand dans toutes les communautés. **Le choix de l'algorithme compte** : sur ce réseau, seul Louvain révèle les groupes de goûts.

**Limite.** Le rôle de pont dépend du découpage de Louvain ; avec d'autres communautés, d'autres utilisateurs seraient « entre » les groupes. Les utilisateurs étant anonymes, on ne sait pas pourquoi ils ont des amis dans plusieurs genres.

---

## En résumé

1. **Les groupes d'amis partagent des goûts musicaux** : avec seulement les amitiés, Louvain retrouve 5 communautés qui correspondent à 5 genres, et la recommandation par les amis fonctionne.
2. **La popularité des artistes est extrêmement inégale** : 60 % des artistes n'ont qu'un auditeur.
3. **Le réseau est un petit monde** fait de cercles d'amis soudés.
4. **Quelques ponts relient les genres**, et ils expliquent pourquoi Label Propagation échoue là où Louvain réussit.
