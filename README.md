# Nexus

Une IA qui vit sur ton téléphone. Pas un chatbot dans le nuage : un **vrai
réseau de neurones** exécuté localement, une **mémoire vierge au départ** qui
grandit avec toi, et des **règles de personnalité que tu écris toi-même**.

Version 0.3.0 — Android 9 (API 28) minimum, téléphone arm64.

## Ce qu'elle est vraiment

- **Un cerveau neuronal** : Qwen3-1.7B (Q4_K_M, 1,03 Go), exécuté par
  llama.cpp directement sur l'appareil. Elle comprend le français, raisonne et
  répond à des questions qu'on ne lui a jamais posées.
- **Zéro réseau à l'usage** : aucune requête ne sort du téléphone. Le modèle est
  téléchargé une seule fois, puis tout se passe hors ligne.
- **Une mémoire qui grandit** : faits sur toi, souvenirs, leçons apprises. Elle
  est réinjectée à chaque message.
- **Une personnalité que tu diriges** : onglet « Cerveau » → « Ses règles ».
- **Une croissance** : stades (nouveau-né → adulte), besoins, humeur, voix.

## Ce qu'elle n'est pas

Soyons précis, parce que c'est important :

- Elle **n'est pas** au niveau de ChatGPT ou Claude. Un modèle de 1,7 milliard de
  paramètres tient dans un téléphone ; GPT-4 et Claude en ont des centaines de
  milliards et tournent sur des milliers de cartes graphiques.
- Elle **ne réentraîne pas ses poids** en te parlant. Aucun modèle au monde ne
  fait ça sur un téléphone : les poids sont gelés après entraînement, même chez
  OpenAI. Ce qui apprend, c'est sa mémoire et ses règles, pas ses neurones.
- Créer un modèle « de zéro » au niveau de ChatGPT demande des dizaines de
  milliers de GPU et des mois : ce n'est pas une option pour une application
  personnelle.

## Installation

1. Télécharge l'APK :
   <https://github.com/leoblanchart92-hub/NEXUS/releases/latest/download/nexus.apk>
2. Installe-le (autorise l'installation depuis cette source).
3. Au premier lancement, donne-lui un nom : elle naît vide, elle ne connaît rien.
4. Onglet **Cerveau** → « Télécharger son cerveau (1,03 Go) », en Wi-Fi.
   Une fois fait, elle fonctionne sans aucune connexion.

## Les trois onglets

- **Parler** : la conversation. La réponse s'écrit en direct.
- **Grandir** : stade, xp, école (apprends-lui un mot), souvenirs, besoins.
- **Cerveau** : installer le modèle, écrire ses règles, vérifier que tout reste
  chez toi.

## Vie privée

Le modèle, la mémoire et les conversations restent dans le stockage privé de
l'application. Aucune donnée n'est envoyée à un serveur. Le seul accès réseau est
le téléchargement initial du modèle et la vérification des mises à jour.

## Mises à jour signées

Chaque build GitHub Actions publie `nexus.apk` et un `update.json` signé en
HMAC-SHA256 sur `version|url|sha256`. L'application recalcule la signature avec la
clé compilée dans l'APK. Sans clé, les mises à jour sont verrouillées.

Pour activer : dépôt → **Settings** → **Secrets and variables** → **Actions** →
`NEXUS_UPDATE_KEY` (valeur : `openssl rand -hex 32`), puis relancer le workflow.

## Construire soi-même

```bash
flutter pub get
flutter analyze
( cd packages/nexus_core && dart test )
flutter build apk --release
```

L'APK sort dans `build/app/outputs/flutter-apk/app-release.apk`.

## Limites connues

- L'interface n'a pas été testée sur un appareil réel (aucun émulateur dans
  l'environnement de développement) : le premier test visuel est le tien.
- Réponses lentes sur les téléphones modestes : c'est un vrai modèle, pas un
  dictionnaire.
- La signature de release utilise encore les clés de debug : Android demandera
  de désinstaller l'ancienne version avant une mise à jour.
