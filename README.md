# Nexus

Une IA qui vit sur ton téléphone. Pas un chatbot dans le nuage : un **vrai
réseau de neurones** exécuté localement, une **mémoire vierge au départ** qui
se remplit toute seule, et des **règles que tu écris toi-même**.

Version 0.7.0 — Android 9 (API 28) minimum, téléphone arm64.

## Ce qu'elle est

- **Un cerveau neuronal** : Qwen3, exécuté par llama.cpp directement sur
  l'appareil. Elle comprend le français, raisonne et répond à des questions
  qu'on ne lui a jamais posées.
- **Quatre cerveaux au choix, tous locaux** : de Qwen3 0.6B (378 Mo, très
  rapide) à Qwen3 4B Instruct 2507 (2,33 Go, le plus juste). Tu en installes
  autant que tu veux, un seul est allumé à la fois, et changer ne coûte rien
  une fois le fichier téléchargé.
- **Elle apprend toute seule** : après chaque échange, le modèle relit la
  conversation et décide lui-même ce qu'il retient — un prénom, un goût, un
  souvenir, un mot expliqué. Rien n'est dicté à la main, il n'y a plus ni
  stades, ni expérience, ni école.
- **Une mémoire que tu peux lire** : l'onglet « Mémoire » montre exactement ce
  qu'elle sait de toi, et permet de tout effacer.
- **Elle est libre** : pas de morale, pas d'avertissements, pas de refus
  polis. Elle donne son avis, répond à ce qu'on lui demande et parle comme
  on lui parle. Ses règles, écrites par toi, précisent sa liberté — elles ne
  la retirent pas.
- **Elle se met à jour elle-même** : l'onglet « Cerveau » télécharge la
  nouvelle version et l'installe, sans passer par un navigateur.
- **Zéro réseau à l'usage** : aucune requête ne sort du téléphone après le
  téléchargement initial du modèle.
- **Une personnalité que tu diriges** : onglet « Cerveau » → « Ses règles ».

## Plusieurs cerveaux

L'onglet **Cerveau** liste les modèles installables et montre pour chacun son
état : *Allumé*, *Installé*, ou à télécharger avec sa taille.

| Cerveau | Taille | Pour qui |
| --- | --- | --- |
| Qwen3 0.6B | 378 Mo | Téléphones modestes, réponses courtes et rapides |
| Qwen3 1.7B | 1,03 Go | Le bon équilibre, recommandé |
| Qwen3 4B | 2,33 Go | Plus posé, demande de la mémoire vive |
| Qwen3 4B Instruct 2507 | 2,33 Go | Le plus juste à l'écrit, le plus lent |

Un seul cerveau est chargé en mémoire à la fois — deux modèles ne tiendraient
pas dans la mémoire vive d'un téléphone. Les fichiers restent sur l'appareil :
« Allumer ce cerveau » recharge simplement celui que tu choisis, sans
retéléchargement. Sa mémoire à elle (ce qu'elle sait de toi) ne dépend pas du
cerveau : tu peux en changer sans rien perdre.

## Ce qu'elle n'est pas

- Elle **n'est pas** au niveau de ChatGPT ou Claude : quelques milliards de
  paramètres tiennent dans un téléphone, contre des centaines de milliards pour
  les modèles de laboratoire.
- Elle **ne réentraîne pas ses poids** en te parlant. Aucun modèle au monde ne
  le fait sur un téléphone : les poids sont gelés, même chez OpenAI. Ce qui
  apprend, c'est sa mémoire — et elle est réelle.

## Installation

1. Télécharge l'APK :
   <https://github.com/leoblanchart92-hub/NEXUS/releases/latest/download/nexus.apk>
2. Installe-le (autorise l'installation depuis cette source).
3. Au premier lancement, tu la mets au monde : elle s'appelle Nexus et elle
   naît vide.
4. Onglet **Cerveau** → choisis un cerveau et télécharge-le (Wi-Fi
   conseillé). Le 1.7B est le bon point de départ. Ensuite, elle fonctionne
   sans aucune connexion.

## Les trois onglets

- **Parler** : la conversation. La réponse s'écrit en direct.
- **Mémoire** : ce qu'elle a retenu d'elle-même (faits, souvenirs, leçons).
- **Cerveau** : choisir et allumer un cerveau, écrire ses règles, faire les
  mises à jour, vérifier que tout reste chez toi.

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

Depuis la 0.6.0, chaque build est signé avec la même clé : les mises à jour
s'installent par-dessus la version en place.

## Vie privée

Le modèle, la mémoire et les conversations restent dans le stockage privé de
l'application. Aucune donnée n'est envoyée à un serveur. Le seul accès réseau
est le téléchargement des cerveaux et la vérification des mises à jour.

## Mises à jour signées

Chaque build GitHub Actions publie `nexus.apk` et un `update.json` signé en
HMAC-SHA256 sur `version|url|sha256`. L'application recalcule la signature avec
la clé compilée dans l'APK, puis contrôle l'empreinte de l'APK téléchargé avant
de l'installer. Sans clé, les mises à jour sont verrouillées.

La clé de signature Android est stable : elle est versionnée dans le dépôt
(`android/app/key.b64`, décodée en `key.jks` par la CI) et sert à toutes les
releases. C'est ce qui rend l'installation par-dessus possible. Son certificat
SHA-256 :
`B0:47:00:04:F1:68:DF:A9:92:5A:60:FA:79:83:2E:F3:0F:3A:61:FA:32:FB:20:C5:44:87:63:00:3F:0A:06:B0`.
La CI compare cette empreinte à celle de chaque APK avant de publier : la ligne
`Signature conforme` dans le journal du build est la preuve que la mise à jour
s'installera par-dessus la version en place.

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
- Les modèles 4B demandent beaucoup de mémoire vive : sur un téléphone
  modeste, le chargement peut échouer. L'application le dit et propose de
  revenir à un cerveau plus léger.
