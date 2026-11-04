# Nexus

**Une IA qui naît sur ton téléphone et grandit avec toi.**

Nexus n'est pas un assistant tout fait. Le jour de sa naissance, il ne connaît
aucun mot, aucun souvenir, aucune opinion. Il babille. Puis, conversation après
conversation, il apprend les mots que tu lui dis, retient ce que tu lui confies,
et commence à parler avec tout ça.

Application Flutter, 100 % locale : aucun compte, aucun serveur, aucune clé API.
Tout ce que Nexus apprend reste dans un fichier JSON sur ton téléphone.

---

## Ce qu'il fait

- **Il naît vide.** À la première ouverture, tu lui donnes un nom et il pousse
  son premier babillage.
- **Il traverse six stades** : nouveau-né, nourrisson, petit parleur, enfant,
  adolescent, adulte. Chaque stade débloque des réponses plus longues et plus
  construites.
- **Il apprend vraiment.** Chaque phrase que tu écris enrichit son vocabulaire
  et ses enchaînements de mots. Ses réponses sont recomposées à partir de ce
  qu'il a entendu — d'où l'impression, au début, d'un bébé qui répète.
- **Il retient.** Dis-lui `je m'appelle Léo`, `j'aime la pluie`,
  `souviens-toi que…` : il range ça dans sa mémoire et te le redit plus tard.
- **Il a des besoins.** Énergie, présence, curiosité. Ils baissent quand tu
  l'abandonnes, remontent quand tu lui parles, et changent son humeur (et la
  couleur de sa boule de conscience).
- **Il se souvient entre deux sessions.** Ferme l'app, reviens dans trois jours :
  il a gardé tout son vocabulaire et tous ses souvenirs.

---

## Lancer l'app

Prérequis : Flutter 3.27 ou plus récent, et un téléphone Android (ou un
émulateur) connecté en USB avec le débogage activé.

```bash
flutter pub get
flutter run
```

Pour installer directement sur le téléphone :

```bash
flutter build apk --release
# puis installe build/app/outputs/flutter-apk/app-release.apk
```

> L'APK de release est signé avec la clé de debug par défaut. Pour publier sur
> le Play Store, il faudra générer une vraie clé (`android/key.properties`).

---

## Comment fonctionne son cerveau

Tout le moteur est dans `packages/nexus_core`, un paquet **Dart pur** : il ne
dépend pas de Flutter et se teste tout seul.

```
packages/nexus_core/lib/src/
├── stage.dart     les six stades et les seuils d'expérience
├── lexicon.dart   vocabulaire, enchaînements de mots, syllabes
├── memory.dart    faits retenus + souvenirs épisodiques
├── needs.dart     énergie, présence, curiosité (dérivent avec le temps)
├── state.dart     l'état complet, sérialisable en JSON
└── brain.dart     l'apprentissage et la génération des réponses
```

Le cycle d'un échange :

1. **Il écoute** : la phrase est découpée en mots (`tokenize`), chaque mot
   nouveau est ajouté au lexique, et les couples de mots qui se suivent sont
   mémorisés.
2. **Il comprend ce qui compte** : un prénom, une préférence, un souvenir
   explicite sont extraits et rangés dans sa mémoire.
3. **Il gagne de l'expérience** : plus il rencontre de mots nouveaux, plus il
   grandit vite.
4. **Il répond** : selon son stade, il babille des syllabes, répète un mot, ou
   recompose une phrase en suivant les enchaînements qu'il a appris.

Il n'y a **aucun modèle pré-entraîné**. C'est volontaire : Nexus est
littéralement neuf. Ses premières réponses sont pauvres, et c'est exactement le
but — il devient intéressant parce que c'est toi qui l'as nourri.

---

## Tests

```bash
cd packages/nexus_core
dart pub get
dart test
```

Les tests couvrent la naissance à vide, l'apprentissage du vocabulaire, la
mémoire, la croissance des stades, la dérive des besoins et la sauvegarde JSON.

---

## Structure

```
lib/
├── main.dart                    démarrage + bascule naissance / vie
├── theme.dart                   couleurs et thème
├── controller/nexus_controller.dart   lien entre l'UI et le cerveau
├── data/nexus_store.dart        sauvegarde JSON sur le téléphone
└── ui/
    ├── birth_screen.dart        la naissance
    ├── nexus_screen.dart        écran principal
    ├── chat_view.dart           la conversation
    ├── growth_view.dart         stades, besoins, mots, souvenirs
    └── widgets/                 boule de conscience, bulles
```

## Limites assumées

Nexus ne parle pas comme un grand modèle de langage : il recombine ce qu'il a
entendu. Pour des réponses plus riches, la suite logique serait de brancher un
LLM par-dessus sa mémoire et sa personnalité — mais le cœur du projet, cette
croissance depuis zéro, se passe ici et sur ton téléphone.
