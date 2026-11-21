# Partie D : Similarité par PageRank personnalisé (D2)

Réseau étudié : le réseau d'amitié (1 892 utilisateurs, 12 717 amitiés), projeté en mémoire avec GDS (projection `friends`). Communautés : celles de Louvain (partie C).
Code : `cypher/05_graph_algorithms.cypher`.

---

## Méthode : la marche aléatoire avec redémarrage

On lance une marche aléatoire depuis un utilisateur de départ. À chaque pas, le marcheur va chez un ami au hasard ; avec une probabilité de 15 %, il revient au point de départ. Le score d'un utilisateur est la part du temps que le marcheur passe chez lui : plus il est élevé, plus l'utilisateur est proche du point de départ. Contrairement au nombre d'amis en commun, cette mesure tient compte de tous les chemins entre deux utilisateurs.

Dans GDS : `gds.pageRank.stream` avec `sourceNodes` (le point de départ) et `dampingFactor: 0.85` (85 % de chances de continuer, 15 % de redémarrer).

### Les 3 utilisateurs choisis

| Utilisateur | Communauté | Rôle | Pourquoi lui |
|---|---|---|---|
| 1213 | Synth-pop 80s | ancré dans sa communauté | 72 % de ses amis sont dans sa communauté (Q11) |
| 1543 | Metal | le plus gros hub | 119 amis, n°1 en betweenness (Q7) |
| 831 | Synth-pop 80s | pont entre communautés | 74,5 % de ses amis hors de sa communauté, participation 0,80 (Q11) |

---

## Les nœuds les plus proches sont-ils dans la même communauté ?

### Tableau 1 : les 10 utilisateurs les plus proches de chacun

| Rang | Depuis 1213 | Depuis 1543 | Depuis 831 |
|---|---|---|---|
| 1 | 859 (Synth-pop) | 1281 (Metal) | 1543 (Metal) |
| 2 | 99 (Synth-pop) | 831 (Synth-pop) | 1210 (Synth-pop) * |
| 3 | 211 (Synth-pop) | 1488 (Metal) * | 1258 (Synth-pop) |
| 4 | 1258 (Synth-pop) | 298 (Metal) | 1956 (petite communauté 1865) |
| 5 | 1343 (Synth-pop) | 1230 (Électro) | 1625 (Électro) |
| 6 | 78 (Électro) * | 1625 (Électro) | 142 (Synth-pop) |
| 7 | 499 (Synth-pop) | 212 (Metal) | 1213 (Synth-pop) |
| 8 | 1164 (Synth-pop) | 1597 (Metal) | 1230 (Électro) |
| 9 | 1543 (Metal) | 78 (Électro) * | 298 (Metal) |
| 10 | 831 (Synth-pop) | 1213 (Synth-pop) | 212 (Metal) |

\* = pas ami direct de l'utilisateur de départ.

### Tableau 2 : synthèse

| Utilisateur | Participation (Q11) | Proches dans la même communauté | Amis directs dans le top 10 | Score du 1er / du 10e |
|---|---|---|---|---|
| 1213 (ancré) | 0,45 | **8 / 10** | 9 / 10 | 0,0071 / 0,0059 |
| 1543 (hub) | 0,62 | **5 / 10** | 8 / 10 | 0,0059 / 0,0034 |
| 831 (pont) | 0,80 | **4 / 10** | 9 / 10 | 0,0056 / 0,0034 |

### Interprétation

- **Oui pour un utilisateur typique.** Pour 1213, bien ancré dans la communauté Synth-pop, 8 des 10 utilisateurs les plus proches sont dans sa communauté : la marche reste dans son cercle. Le PageRank personnalisé confirme les communautés de Louvain.
- **De moins en moins pour les hubs et les ponts.** Plus les amis d'un utilisateur sont répartis entre les communautés (participation de 0,45 à 0,80), moins ses voisins proches sont dans sa propre communauté (de 8/10 à 4/10). Pour 1543, on retrouve les trois genres avec lesquels il a des liens (Metal, Électro, Synth-pop).
- **Les gros connecteurs sont proches les uns des autres.** Les hubs et ponts (1543, 1281, 831, 298, 1597, 78) apparaissent dans les listes les uns des autres : ils forment un cœur qui relie les communautés.
- **Des voisins proches qui ne sont pas amis.** 78 (pour 1213), 1488 (pour 1543) et 1210 (pour 831) sont très proches sans être amis : la marche y arrive par de nombreux chemins courts. Ce sont des suggestions d'amis naturelles.
- **Les scores des hubs sont plus faibles.** 1543 a 119 amis : la marche se répartit entre plus d'utilisateurs, et chacun reçoit un score plus petit.
- **Biais des hubs.** Pour 831, aucun fan de Pop teen n'apparaît dans le top 10, alors que 24 % de ses amis sont dans cette communauté. Ses amis Metal (1543, 298, 212) sont des hubs, et la marche passe plus souvent par eux.

---

## Cas d'usage : recommandation de musique

Pour l'utilisateur 1213, on recommande les artistes écoutés par ses 20 utilisateurs les plus proches qu'il n'écoute pas encore. Le score d'un artiste est la somme des scores PageRank des utilisateurs proches qui l'écoutent.

**Ce qu'écoute déjà 1213 :** De/Vision, Magic Man, e-gens, Electro Spectre, Depeche Mode, Provision, Analog Angel, B! Machine, Jens Bader, Ien Oblique : un fan de synth-pop et d'électro-pop.

### Tableau 3 : recommandations pour 1213

| Rang | Artiste | Proches qui l'écoutent | Score | Commentaire |
|---|---|---|---|---|
| 1 | Dave Gahan | 9 | 0,0534 | chanteur de Depeche Mode (solo) |
| 2 | Recoil | 9 | 0,0526 | projet d'Alan Wilder, ancien membre de Depeche Mode |
| 3 | Madonna | 9 | 0,0518 | pop très populaire |
| 4 | Martin L. Gore | 8 | 0,0464 | compositeur de Depeche Mode (solo) |
| 5 | Lady Gaga | 7 | 0,0424 | artiste la plus écoutée du dataset |
| 6 | Hurts | 7 | 0,0411 | synth-pop |
| 7 | Placebo | 6 | 0,0385 | rock alternatif |
| 8 | The Cure | 6 | 0,0368 | new wave / post-punk |
| 9 | Radiohead | 6 | 0,0366 | rock alternatif |
| 10 | U2 | 6 | 0,0359 | rock des années 80 |

### Interprétation

- **La recommandation est pertinente.** 1213 écoute Depeche Mode, et les trois premières recommandations de niche sont les projets solo de trois membres de Depeche Mode. Le système n'utilise que les amitiés et les écoutes : il ne sait pas que ces artistes sont liés, il le découvre grâce aux utilisateurs proches.
- **Les recommandations correspondent à la communauté.** Dave Gahan et Martin L. Gore font partie des artistes typiques de la communauté Synth-pop en Q10 (lift ≈ 7) ; Hurts, The Cure et Placebo sont dans le même univers.
- **Lien avec la question Q1.** Comme les amis partagent les mêmes goûts, on peut recommander de la musique à partir du réseau d'amitié.

**Autre cas d'usage :** la suggestion d'amis, en proposant les utilisateurs proches qui ne sont pas encore amis (78, 1488, 1210).

---

## Limites

- **Biais des hubs :** la marche passe plus souvent par les utilisateurs très connectés, qui remontent dans le classement même s'ils sont dans une autre communauté.
- **Biais de popularité :** les artistes très populaires (Madonna, Lady Gaga) remontent dans les recommandations. Il faudrait diviser le score par la popularité de l'artiste, comme le lift de la Q10.
- **Seulement 3 utilisateurs testés :** pour une conclusion générale, il faudrait mesurer la part de voisins proches dans la même communauté sur tous les utilisateurs.
- **Paramètre de redémarrage :** 15 % est le choix standard ; une autre valeur changerait un peu les résultats.
