# Nexus

Une IA qui vit sur ton téléphone. Pas un chatbot dans le nuage : un **vrai
réseau de neurones** exécuté localement, une **mémoire vierge au départ** qui
se remplit toute seule, et des **règles que tu écris toi-même**.

Version 0.5.0 — Android 9 (API 28) minimum, téléphone arm64.

## Ce qu'elle est

- **Un cerveau neuronal** : Qwen3-1.7B (Q4_K_M, 1,03 Go), exécuté par
  llama.cpp directement sur l'appareil. Elle comprend le français, raisonne
  et répond à des questions qu'on ne lui a jamais posées.
- **Elle apprend toute seule** : après chaque échange, le modèle relit la
  conversation et décide lui-même ce qu'il retient — un prénom, un goût, un
  souvenir, un mot expliqué. Rien n'est dicté à la main, il n'y a plus ni
  stades, ni expérience, ni école.
- **Une mémoire que tu peux lire** : l'onglet « Mémoire » montre exactement ce
  qu'elle sait de toi, et permet de tout effacer.
- **Elle se met à jour elle-même** : l'onglet « Cerveau » télécharge la
  nouvelle version et l'installe, sans passer par un navigateur.
- **Zéro réseau à l'usage** : aucune requête ne sort du téléphone après le
  téléchargement initial du modèle.
- **Une personnalité que tu diriges** : onglet « Cerveau » → « Ses règles ».

## Ce qu'elle n'est pas

- Elle **n'est pas** au niveau de ChatGPT ou Claude : 1,7 milliard de
  paramètres tient dans un téléphone, contre des centaines de milliards pour
  les modèles de laboratoire.
- Elle **ne réentraîne pas ses poids** en te parlant. Aucun modèle au monde ne
  le fait sur un téléphone : les poids sont gelés, même chez OpenAI. Ce qui
  apprend, c'est sa mémoire — et elle est réelle.

## Installation

1. Télécharge l'APK :
   <https://github.com/leoblanchart92-hub/NEXUS/releases/latest/download/nexus.apk>
2. Installe-le (autorise l'installation depuis cette source).
3. Au premier lancement, donne-lui un nom : elle naît vide.
4. Onglet **Cerveau** → « Télécharger son cerveau (1,03 Go) », en Wi-Fi.
   Ensuite, elle fonctionne sans aucune connexion.

## Les trois onglets

- **Parler** : la conversation. La réponse s'écrit en direct.
- **Mémoire** : ce qu'elle a retenu d'elle-même (faits, souvenirs, leçons).
- **Cerveau** : installer le modèle, écrire ses règles, faire les mises à
  jour, vérifier que tout reste chez toi.

## Mises à jour depuis l'application

Onglet **Cerveau** → carte « Mise à jour ». Nexus lit son manifeste signé, et
si une version plus récente existe, elle la télécharge elle-même, vérifie son
empreinte SHA-256, puis demande à Android de l'installer : on ne quitte jamais
l'application. Une pastille apparaît sur l'onglet Cerveau dès qu'une version
attend d'être installée.

Android 8+ demande une autorisation explicite (« Installer des applications
inconnues ») : la carte propose le bouton qui ouvre directement le bon écran.
Si l'installation automatique échoue, le bouton « Ouvrir la page de
téléchargement » reste disponible en secours.

## Vie privée

Le modèle, la mémoire et les conversations restent dans le stockage privé de
l'application. Aucune donnée n'est envoyée à un serveur. Le seul accès réseau
est le téléchargement initial du modèle et la vérification des mises à jour.

## Mises à jour signées

Chaque build GitHub Actions publie `nexus.apk` et un `update.json` signé en
HMAC-SHA256 sur `version|url|sha256`. L'application recalcule la signature avec
la clé compilée dans l'APK, puis contrôle l'empreinte de l'APK téléchargé avant
de l'installer. Sans clé, les mises à jour sont verrouillées.

## Construire soi-même

```bash
flutter pub get
flutter analyze
( cd packages/nexus_core && dart test )
flutter build apk --release
```

## Limites connues

- L'interface n'a pas été testée sur un appareil réel (aucun émulateur dans
  l'environnement de développement) : le premier test visuel est le tien.
- Réponses lentes sur les téléphones modestes : c'est un vrai modèle.
- L'apprentissage ajoute une seconde génération courte après chaque réponse :
  la mémoire s'écrit quelques secondes après que la réponse s'affiche.
