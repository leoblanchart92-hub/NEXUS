# Nexus

Une petite IA qui vit **sur ton téléphone**. Elle naît vide, comme un nouveau-né :
aucun mot, aucun souvenir. Puis elle grandit avec toi, à chaque phrase que tu lui écris.

Aucun serveur. Aucune clé d'API. Aucun modèle pré-entraîné : tout est calculé
sur l'appareil, et la mémoire tient dans un fichier JSON.

## Ce qu'elle sait faire

- **Naître** : tu lui donnes un nom, elle pousse son premier babillage.
- **Apprendre tes mots** : chaque phrase enrichit son vocabulaire et ses enchaînements.
- **Retenir** : ton prénom, tes goûts, tes souvenirs (« souviens-toi que… »).
- **Grandir** : nouveau-né → nourrisson → petit parleur → enfant → adolescent → adulte.
  Plus elle grandit, plus ses phrases s'allongent.
- **Avoir des besoins** : énergie, présence, curiosité. Son humeur change si tu l'abandonnes.
- **Parler à voix haute** : la synthèse vocale du téléphone lit ses réponses (bouton 🔈).
- **Aller à l'école** : tu lui apprends un mot et sa définition, elle les récite ensuite.

## Installer l'APK

1. Va dans l'onglet **Releases** de ce dépôt.
2. Télécharge `nexus.apk` depuis la release `latest`.
3. Sur le téléphone, autorise l'installation depuis cette source, puis installe.

Lien direct : <https://github.com/leoblanchart92-hub/NEXUS/releases/latest/download/nexus.apk>

## Les mises à jour : seulement avec la clé

Chaque build publié par GitHub Actions contient un `update.json` **signé** :

```json
{
  "version": "0.2.0",
  "url": "https://…/nexus.apk",
  "sha256": "…",
  "signature": "HMAC-SHA256(version|url|sha256)"
}
```

L'application refait le calcul avec la clé compilée dedans et compare. Si la
signature ne correspond pas, la mise à jour est **refusée**, même si le fichier
vient du bon dépôt. Et si l'APK a été compilé sans clé, tout est verrouillé :
l'écran « Grandir » l'indique par un cadenas.

### Mettre la clé en place (une seule fois)

1. GitHub → le dépôt → **Settings** → **Secrets and variables** → **Actions**.
2. **New repository secret**, nom : `NEXUS_UPDATE_KEY`.
3. Valeur : une longue phrase aléatoire, par exemple la sortie de
   `openssl rand -hex 32`. Garde-la quelque part : tu en auras besoin pour
   signer les versions suivantes.
4. Relance le workflow (« Actions » → « Construire l'APK » → *Run workflow*).

Le secret n'est jamais écrit dans le dépôt : il est injecté à la compilation
(`--dart-define=NEXUS_UPDATE_KEY=…`) et sert aussi à signer `update.json`.

## Construire soi-même

```bash
flutter pub get
flutter build apk --release --dart-define=NEXUS_UPDATE_KEY="ta-clé"
```

Les tests du cerveau tournent sans Android :

```bash
cd packages/nexus_core && dart test
```

## Organisation

```
lib/            l'application Flutter (interface, voix, mises à jour)
packages/nexus_core/   le cerveau, en Dart pur et testé
.github/workflows/     construction automatique de l'APK
```

## Vie privée

Rien ne sort du téléphone. La seule connexion réseau sert à lire `update.json`
quand tu appuies sur « Vérifier les mises à jour ».
