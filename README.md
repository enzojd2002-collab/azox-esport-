# AZOX Esport — prototype V4

## Contenu
- `index.html` : site autonome, logo AZOX intégré, navigation par pages.
- `supabase-schema.sql` : tables Supabase, profils initiaux sans statistiques, vue du classement et règles RLS.
- `README.md` : instructions.

## Tester maintenant
1. Décompresser le dossier.
2. Ouvrir `index.html` avec Chrome, Firefox ou Edge.
3. Ouvrir **MENU > PROFILS JOUEURS** pour consulter Rome, Lucky et Sacha.
4. Ouvrir **MENU > GESTION LOCALE** pour compléter les profils et ajouter des résultats réels.
5. Le classement se recalcule à partir des points saisis.
6. Utiliser **EXPORTER JSON** pour sauvegarder les données locales.

Aucune statistique n'est préremplie. Les champs inconnus affichent « À compléter » ou « — ».

## Limite importante du prototype
Les modifications sont stockées dans le `localStorage` du navigateur. Elles ne sont visibles que sur cet appareil et ce navigateur. Ce n'est pas encore une base partagée et la page de gestion locale n'est pas protégée : ne publiez pas cette version telle quelle en la présentant comme un vrai espace administrateur.

## Préparer la base partagée avec Supabase
1. Créer un projet Supabase.
2. Ouvrir **SQL Editor**, coller `supabase-schema.sql`, puis exécuter le script.
3. Les tables créées sont `azox_players` et `azox_results`. La vue `azox_ranking` calcule le classement.
4. Créer l'authentification des administrateurs et attribuer le rôle `azox_admin` dans `app_metadata` depuis un environnement de confiance.
5. Connecter ensuite le site à Supabase avec l'URL du projet et la clé publique `anon`. Les politiques RLS du script autorisent la lecture publique et réservent les écritures aux administrateurs.

**Ne jamais intégrer la clé `service_role` dans le HTML, dans GitHub ou dans un fichier distribué au public.**

## Règle du classement
Le classement additionne les champs `points` des résultats saisis. Un joueur sans résultat avec points reste non classé. En cas d'égalité, les joueurs partagent le même rang. Ce barème est une base technique, à valider par l'équipe avant la mise en production.
