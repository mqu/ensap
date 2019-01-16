# ensap
ENSAP API to download pay sheets from gouvernemental Web site.

Work in progress ; please experiment or wait :-)

## C'est quoi

ce projet permet de télécharger et de mettre en synchro dans un répertoire local, les fiches de paie numérisées hébergées sur le site gouvernemental. 

L'ensemble est réalisé en ruby et permet de s'authentifier sur le site et d'effectuer automatiquement le téléchargement au format PDF, l'ensemble des documents présentés sur l'espace lié aux rémunération. En activant une fois par mois ce service, on peut s'assurer d'avoir une synchro parfaite des documents numérisés localement.

Par ailleurs, je projete de réaliser un container Docker permettant de simplifier l'acces à ce service.

## Mise en place :

Le vidéo-turoriel devrait suffir : https://www.dailymotion.com/video/x6kbaon
- 1 : création de l'espace numérique sécurisé : numéro de sécu, nom et date de naissance
- 2 : compléter par les références bancaires.

## utilisation

- le script a besoin du login (numéro SECU) et mot de passe ; 
- à terme, on pourra passer ces paramêtres via des options avec des actions : ls, dl(all,2019,current).

## TODO

- parse PDF to extract some information aboit pay-sheet content.
- extend CLI options.
- extend docker container usability.
- study distroless containers
