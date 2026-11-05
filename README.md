# Nexus

Télécharge des IA sur ton téléphone, allume celle que tu veux, éteins-la quand
tu veux. Tout tourne **en local** : après le téléchargement, aucune requête ne
sort de l'appareil.

Version 0.10.0 — Android 9 (API 28) minimum, téléphone arm64.

## Ce qu'elle fait

- **Quatre IA au choix, toutes locales** : de Qwen3 0.6B (378 Mo, très rapide)
  à Qwen3 4B Instruct 2507 (2,33 Go, la plus juste). Chacune est un vrai réseau
  de neurones (GGUF Q4_K_M), exécuté par llama.cpp sur l'appareil.
- **On télécharge d'abord, on allume ensuite** : une IA qu'on n'a pas
  téléchargée ne peut pas être allumée. Le bouton affiche sa taille réelle et
  la progression du téléchargement, en pourcentage et en octets.
- **Allumer / éteindre** : allumer charge les poids du modèle en mémoire vive ;
  éteindre les libère. Le fichier reste sur le téléphone, donc rallumer ne
  retélécharge rien.
- **Une seule IA à la fois** : deux modèles ensemble ne tiendraient pas dans la
  mémoire vive d'un téléphone. Allumer la seconde éteint la première.
- **Supprimer pour récupérer la place** : avec confirmation, puisqu'il faudra
  retélécharger le fichier.
- **Mises à jour depuis l'application** : au lancement, Nexus regarde s'il
  existe une version plus récente ; une bannière propose alors de la
  télécharger et de l'installer, sans passer par le navigateur.

| IA | Taille | Pour qui |
| --- | --- | --- |
| Qwen3 0.6B | 378 Mo | Téléphones modestes, réponses courtes et rapides |
| Qwen3 1.7B | 1,03 Go | Le bon équilibre, recommandée pour commencer |
| Qwen3 4B | 2,33 Go | Plus posée, demande de la mémoire vive |
| Qwen3 4B Instruct 2507 | 2,33 Go | La plus juste à l'écrit, la plus lente |

Les fichiers viennent de Hugging Face (`unsloth/Qwen3-*-GGUF`), en Q4_K_M :
c'est le meilleur rapport taille / qualité pour un téléphone. Le
téléchargement se fait une seule fois, en Wi-Fi de préférence.

## Installation

1. Télécharge l'APK :
   <https://github.com/leoblanchart92-hub/NEXUS/releases/latest/download/nexus.apk>
2. Installe-le (autorise l'installation depuis cette source).
3. Ouvre Nexus : chaque IA affiche sa taille.
4. Appuie sur **Télécharger** sur celle que tu veux (le 1.7B est le bon point
   de départ), puis sur **Allumer** une fois le fichier arrivé.

## Vie privée

Le modèle téléchargé reste dans le stockage privé de l'application. Aucune
donnée n'est envoyée à un serveur : le seul accès réseau est le téléchargement
d'un modèle, et la vérification des mises à jour de l'APK.

## Mises à jour signées

Chaque build GitHub Actions publie `nexus.apk` et un `update.json` signé en
HMAC-SHA256 sur `version|url|sha256`.

Dans l'application, le cycle est le suivant :

1. au lancement, `lib/app_update.dart` lit `update.json` (une requête, rien
d'autre) et compare sa `version` à celle compilée dans l'app ;
2. si une version plus récente existe, une bannière « Nexus x.y.z est
   disponible » apparaît en haut de l'écran ; en bas, un lien « Vérifier les
   mises à jour » permet de relancer la vérification à la main ;
3. « Télécharger et installer » récupère l'APK dans le stockage privé de
   l'application, avec la progression en pourcentage, puis vérifie son
   empreinte SHA-256 et la signature du manifeste ;
4. le fichier vérifié est confié au programme d'installation d'Android par un
   canal natif (`nexus/installer`, `MainActivity.kt` + FileProvider) :
   l'installation se fait par-dessus la version en place, sans toucher aux
   fichiers des IA déjà téléchargées.

Android demande une seule fois l'autorisation « installer des applications
inconnues » pour Nexus : l'application affiche alors un bouton qui ouvre
directement le bon réglage, puis il suffit de réappuyer sur « Installer ».
Si la signature ou l'empreinte ne correspond pas, l'APK est supprimé et rien
n'est installé.

La clé de signature Android est stable : elle est versionnée dans le dépôt
(`android/app/key.b64`, décodée en `key.jks` par la CI) et sert à toutes les
releases. C'est ce qui rend l'installation par-dessus la version en place
possible. Son certificat SHA-256 :
`B0:47:00:04:F1:68:DF:A9:92:5A:60:FA:79:83:2E:F3:0F:3A:61:FA:32:FB:20:C5:44:87:63:00:3F:0A:06:B0`.
La CI compare cette empreinte à celle de chaque APK avant de publier : la ligne
`Signature conforme` dans le journal du build est la preuve que la mise à jour
s'installera par-dessus la version en place.

## Construire soi-même

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## Limites connues

- L'interface n'a pas été testée sur un appareil réel (aucun téléphone dans
  l'environnement de développement) : le premier test visuel est le tien.
- La mise à jour automatique n'existe qu'à partir de la 0.10.0 : depuis une
  0.9.0, il faut installer cette version à la main une dernière fois.
- Les modèles 4B demandent beaucoup de mémoire vive : sur un téléphone
  modeste, l'allumage peut échouer. L'application le dit et propose d'essayer
  une IA plus légère.
- Télécharger 1 à 2,5 Go consomme de la data : à faire en Wi-Fi.
