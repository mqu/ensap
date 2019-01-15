# ensap
ENSAP API to download pay sheets from gouvernemental Web site.

Work in progress ; please experiment or wait :-)

## C'est quoi

ce projet permet de télécharger et de mettre en synchro dans un répertoire local, les fiches de paie numérisées hébergées sur le site gouvernemental. 

L'ensemble est réalisé en ruby et permet de s'authentifier sur le site et d'effectuer automatiquement le téléchargement au format PDF, l'ensemble des documents présentés sur l'espace lié aux rémunération. En activant une fois par mois ce service, on peut s'assurer d'avoir une synchro parfaite des documents numérisés localement.

Par ailleurs, je projete de réaliser un container Docker permettant de simplifier l'acces à ce service.

Restiction : 
- je ne dispose sur mon compte que des années 2016 à la date courante
- 

## Mise en place :

Le vidéo-turoriel devrait suffir : https://www.dailymotion.com/video/x6kbaon

## TODO

- parse PDF to extract some information aboit pay-sheet content.
- extend CLI options.
- extend docker usability.
