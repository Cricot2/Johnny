# Johnny

SuperCollider Wii Guitare héro. 
With OSCulator app.

Need a Wii + Guitare controler + OSCulator.
Need SC3 plug ins...

http://supercollider.github.io/sc3-plugins/

---

# Note Update pour Ben:

J'ai rajouté un potard Tune pour l'accordage de 'Que je t'aime'.

J'ai changé les envellopes des notes de 'Que je t'aime', une nouvelles note chasse l'autre et évite les superpositions laides.

J'ai changé en interne la logique de cette partie, pour info ce sont des sons enregistrés de la synthèse qu'il y avait avant, c'est ce qui permet l'accordage...

### Installation:

Clone le dossier Github complet dans Document. Y'a de nouveaux sons dans le dossier soundFiles donc il n'est pas compatible avec l'ancien (a moins que tu copie soundFiles avec).

### Utilisation:

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Attention !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Quand tu relance le script (genre avant de jouer pour faire ta mise) tu efface le réglage de l'accordage...

> Soit tu fais ta mise en faisant dérouler les notes de 'Que je t'aime' et tu Lock la commande avant de jouer, sans relancer le script.

> Soit tu peux ''hard coder" la valeur de l'accordage **ligne 13**:

```smalltalk
// Init the fine tune for guitare_melodieUp.
fineTune = 1;
```

Dans ce cas quand tu relance le script elle est initialisée.

Par exemple tu peux faire:

```smalltalk
// Init the fine tune for guitare_melodieUp.
fineTune = 0.9;
```

Le range de l'accordage va de 0.9 à 1.1 ce qui fait déjà pas mal de marge à l'oreille. Les valeurs du potard s'affichent dans la postwindow.


